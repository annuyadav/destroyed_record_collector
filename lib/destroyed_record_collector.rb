module DestroyedRecordCollector
  BACKED_AT_COLUMN_NAME = :backed_up_at

  def self.included(base)
    base.send :include, InstanceMethods
    base.send(:before_destroy, :write_backup)
  end

  module InstanceMethods

    def write_backup
      begin
        make_backup unless (self.respond_to?(:exclude_from_backup) and (self.exclude_from_backup == true))
      rescue Exception => e
        Rails.logger.debug "Exception occurred: #{e.message.inspect}"
        e.backtrace.each { |line| Rails.logger.debug(line.inspect) }
      end
    end

    def make_backup
      arClass = get_class

      arClass.establish_connection(new_backup_connection_available) unless new_backup_connection_available.nil?
      arClass.connection.tables #To register an active connection in connection_pool

      if arClass.connected?
        con_configurations = ActiveRecord::Base.configurations
        arClass.table_name = (((not con_configurations["#{Rails.env}_backup"].nil?) and (con_configurations[Rails.env] != con_configurations["#{Rails.env}_backup"])) ? self.class.table_name : "#{self.class.table_name}_backup")
        generate_table(arClass) unless arClass.table_exists?
        do_record_backup(arClass)
      else
        raise "BackupConnectionFailedToEstablish"
      end
    end

    def new_backup_connection_available
      ActiveRecord::Base.configurations["#{Rails.env}_backup"]
    end

    def add_column(arClass, column_name)
      arClass.connection.change_table arClass.table_name do |t|
        t.column(column_name, columns_hash[column_name].type)
      end
    end

    def generate_table(arClass)
      arClass.connection.create_table arClass.table_name do |t|
        self.attributes.keys.each do |attribute|
          t.column attribute, columns_hash[attribute].type
        end
        t.column BACKED_AT_COLUMN_NAME, :datetime
      end
    end

    def columns_hash
      self.class.columns_hash
    end

    def do_record_backup(arClass)
      backup_entity = arClass.new

      attributes.keys.each { |attribute| add_column(arClass, attribute) unless backup_entity.respond_to?("#{attribute}=") }
      arClass.reset_column_information
      backup_entity = arClass.new
      self.attributes.merge({BACKED_AT_COLUMN_NAME => Time.now}).each do |attribute_name, attribute_value|
        backup_entity.send("#{attribute_name}=", attribute_value)
      end
      backup_entity.save
    end

    def get_class(class_name = "#{self.class.name}Backup")
      is_an_armodel?(class_name) ? class_name.constantize : create_class(class_name)
    end

    def is_an_armodel?(class_name)
      begin
        return (class_name.constantize.ancestors.include?(ActiveRecord::Base))
      rescue Exception => e
        return false
      end
      true
    end

    def create_class(name, inherited_from = ActiveRecord::Base)
      Object.const_set(name, Class.new(inherited_from))
    end

  end
end


ActiveRecord::Base.send :include, DestroyedRecordCollector
