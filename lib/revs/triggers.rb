require 'eventswarm-jar'

# manage the registration of actions against EventSwarm triggers, since this is a bit tricky via jruby
class Triggers
  class << self
    # register an add event action
    def add(trigger, action)
      trigger.java_send :registerAction, [Java::com::eventswarm::AddEventAction.java_class], java_object(action)
    end

    # register a match action
    def match(trigger, action)
      trigger.java_send :registerAction, [Java::com::eventswarm::expressions::EventMatchAction.java_class], java_object(action)
    end

    # register a complex match action
    def complex_match(trigger, action)
      trigger.java_send :registerAction, [Java::com::eventswarm::expressions::ComplexExpressionMatchAction.java_class], java_object(action)
    end

    # register a remove event action
    def remove(trigger, action)
      trigger.java_send :registerAction, [Java::com::eventswarm::RemoveEventAction.java_class], java_object(action)
    end

    # register a new set action
    def new_set(trigger, action)
      trigger.java_send :registerAction, [Java::com::eventswarm::powerset::NewSetAction.java_class], java_object(action)
    end

    # register a remove set action
    def remove_set(trigger, action)
      trigger.java_send :registerAction, [Java::com::eventswarm::powerset::RemoveSetAction.java_class], java_object(action)
    end

    # register a new schedule action
    def schedule(trigger, action)
      trigger.java_send :registerAction, [Java::com::eventswarm::schedules::Schedule.java_class], java_object(action)
    end

    # register a new tick action
    def tick(trigger, action)
      trigger.java_send :registerAction, [Java::com::eventswarm::schedules::TickAction.java_class], java_object(action)
    end

    # register a powerset add event action
    def add_pset(trigger, action)
      trigger.java_send :registerAction, [Java::com::eventswarm::powerset::PowersetAddEventAction.java_class], java_object(action)
    end

    # register a powerset remove event action
    def remove_pset(trigger, action)
      trigger.java_send :registerAction, [Java::com::eventswarm::powerset::PowersetRemoveEventAction.java_class], java_object(action)
    end

    # register both add and remove actions for target
    def add_remove(trigger, action)
      add(trigger, action)
      remove(trigger, action)
    end

    # unregister an add event action
    def un_add(trigger, action)
      trigger.java_send :unregisterAction, [Java::com::eventswarm::AddEventAction.java_class], java_object(action)
    end

    # unregister a match action
    def un_match(trigger, action)
      trigger.java_send :unregisterAction, [Java::com::eventswarm::expressions::EventMatchAction.java_class], java_object(action)
    end

    # unregister a complex match action
    def un_complex_match(trigger, action)
      trigger.java_send :unregisterAction, [Java::com::eventswarm::expressions::ComplexExpressionMatchAction.java_class], java_object(action)
    end

    # unregister a remove event action
    def un_remove(trigger, action)
      trigger.java_send :unregisterAction, [Java::com::eventswarm::RemoveEventAction.java_class], java_object(action)
    end

    # unregister a new set action
    def un_new_set(trigger, action)
      trigger.java_send :unregisterAction, [Java::com::eventswarm::powerset::NewSetAction.java_class], java_object(action)
    end

    # unregister a remove set action
    def un_remove_set(trigger, action)
      trigger.java_send :unregisterAction, [Java::com::eventswarm::powerset::RemoveSetAction.java_class], java_object(action)
    end

    # un_register a new schedule action
    def un_schedule(trigger, action)
      trigger.java_send :unregisterAction, [Java::com::eventswarm::schedules::Schedule.java_class], java_object(action)
    end

    # unregister both add and remove actions for target
    def un_add_remove(trigger, action)
      un_add(trigger, action)
      un_remove(trigger, action)
    end

    def is_remove?(trigger)
      trigger.java_kind_of? com.eventswarm.RemoveEventTrigger
    end

    def is_add?(trigger)
      trigger.java_kind_of? com.eventswarm.AddEventTrigger
    end

    def is_match?(trigger)
      trigger.java_kind_of? com.eventswarm.expressions.EventMatchTrigger
    end

    def is_complex_match?(trigger)
      trigger.java_kind_of? com.eventswarm.expressions.ComplexExpressionMatchTrigger
    end

    def is_threshold?(trigger)
      trigger.java_kind_of? com.eventswarm.SizeThresholdTrigger
    end

    def is_new_set?(trigger)
      trigger.java_kind_of? com.eventswarm.powerset.NewSetTrigger
    end

    def is_remove_set?(trigger)
      trigger.java_kind_of? com.eventswarm.powerset.RemoveSetTrigger
    end

    def execute_add(trigger, action, event)
      action.java_send :execute, [Java::com::eventswarm::AddEventTrigger.java_class, Java::com::eventswarm::events::Event.java_class], java_object(trigger), java_object(event)
    end

    def execute_remove(trigger, action, event)
      action.java_send :execute, [Java::com::eventswarm::RemoveEventTrigger.java_class, Java::com::eventswarm::events::Event.java_class], java_object(trigger), java_object(event)
    end

    private

    # if this is a java Action object, unwrap it, otherwise just use the ruby object
    def java_object ruby_object
      ruby_object.respond_to?(:java_object) ? ruby_object.java_object : ruby_object
    end
  end
end
