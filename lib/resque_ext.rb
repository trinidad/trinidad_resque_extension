require 'resque'

module Resque
  class Worker
    # if we let resque trap signals trinidad cannot ever be stopped
    alias :old_register_signal_handlers :register_signal_handlers

    def register_signal_handlers
    end
  end
end
