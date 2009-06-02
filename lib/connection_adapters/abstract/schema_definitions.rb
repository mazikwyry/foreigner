module Foreigner
  class ForeignKey < Struct.new(:base, :to_table, :options)
    def to_sql
      base.foreign_key_definition(to_table, options)
    end
    alias to_s :to_sql
  end
  
  module TableDefinition
    def self.included(base)
      base.class_eval do
        include InstanceMethods
        alias_method_chain :references, :foreign_keys
        alias_method_chain :to_sql, :foreign_keys
      end
    end
    
    module InstanceMethods
      # Adds a foreign key in addition to the reference column.
      # No foreign key is created if :polymorphic => true is used.
      # 
      # ===== Examples
      # ====== Add goat_id column and a foreign key to the goats table.
      #  t.references(:goat)
      # ====== Add goat_id column and a cascading foreign key to the goats table.
      #  t.references(:goat, :dependent => :delete)
      def references_with_foreign_keys(*args)
        options = args.extract_options!
        args.each { |to_table| foreign_key(to_table, options) } unless options[:polymorphic]
        references_without_foreign_key(*(args << options))
      end
    
      # Defines a foreign key for the table. +to_table+ can be a single Symbol, or
      # an Array of Symbols. See SchemaStatements#add_foreign_key
      #
      # ===== Examples
      # ====== Creating a simple foreign key
      #  t.foreign_key(:people)
      # ====== Defining the column
      #  t.foreign_key(:people, :column => :sender_id)
      # ====== Creating a named foreign key
      #  t.foreign_key(:people, :column => :sender_id, :name => 'sender_foreign_key')
      def foreign_key(to_table, options = {})
        foreign_keys << ForeignKey.new(@base, to_table, options)
      end
      
      def to_sql_with_foreign_keys
        to_sql_without_foreign_keys + ', ' + (foreign_keys * ', ')
      end
      
      private
        def foreign_keys
          @foreign_keys ||= []
        end
    end
  end

  module TableMethods
    def self.included(base)
      base.class_eval do
        include InstanceMethods
        alias_method_chain :references, :foreign_keys
      end
    end

      module InstanceMethods
      # Adds a new foreign key to the table. +to_table+ can be a single Symbol, or
      # an Array of Symbols. See SchemaStatements#add_foreign_key
      #
      # ===== Examples
      # ====== Creating a simple foreign key
      #  t.foreign_key(:people)
      # ====== Defining the column
      #  t.foreign_key(:people, :column => :sender_id)
      # ====== Creating a named foreign key
      #  t.foreign_key(:people, :column => :sender_id, :name => 'sender_foreign_key')
      def foreign_key(to_table, options = {})
        @base.add_foreign_key(@table_name, to_table, options)
      end
    
      # Remove the given foreign key from the table.
      #
      # ===== Examples
      # ====== Remove the suppliers_company_id_fk in the suppliers table.
      #   t.remove_foreign_key :companies
      # ====== Remove the foreign key named accounts_branch_id_fk in the accounts table.
      #   remove_foreign_key :column => :branch_id
      # ====== Remove the foreign key named party_foreign_key in the accounts table.
      #   remove_index :name => :party_foreign_key
      def remove_foreign_key(options = {})
        @base.remove_foreign_key(@table_name, options)
      end
      
      # Adds a foreign key in addition to the reference column.
      # No foreign key is created if :polymorphic => true is used.
      # 
      # ===== Examples
      # ====== Add goat_id column and a foreign key to the goats table.
      #  t.references(:goat)
      # ====== Add goat_id column and a cascading foreign key to the goats table.
      #  t.references(:goat, :dependent => :delete)
      def references_with_foreign_keys(*args)
        options = args.extract_options!
        polymorphic = options[:polymorphic]
        references_without_foreign_key(*(args << options))

        args.each { |to_table| foreign_key(to_table, options) } unless polymorphic
      end
    end
  end
end
