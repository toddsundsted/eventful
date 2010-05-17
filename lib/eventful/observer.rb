#
# observer.rb implements the _Observer_ object-oriented design pattern.  The
# following documentation is copied, with modifications, from "Programming
# Ruby", by Hunt and Thomas; http://www.rubycentral.com/book/lib_patterns.html.
#
# == About
#
# The Observer pattern, also known as Publish/Subscribe, provides a simple
# mechanism for one object to inform a set of interested third-party objects
# when its state changes.
#
# == Mechanism
#
# In the Ruby implementation, the notifying class mixes in the +Observable+
# module, which provides the methods for managing the associated observer
# objects.
#
# The observers must implement the +observable_changed+ method to receive
# notifications.
#
# The observable object must:
# * assert that it has +changed+
# * call +notify_observers+
#
# == Example
#
# The following example demonstrates this nicely.  A +Ticker+, when run,
# continually receives the stock +Price+ for its +@symbol+.  A +Warner+ is a
# general observer of the price, and two warners are demonstrated, a +WarnLow+
# and a +WarnHigh+, which print a warning if the price is below or above their
# set limits, respectively.
#
# The +observable_changed+ callback allows the warners to run without being
# explicitly called.  The system is set up with the +Ticker+ and several
# observers, and the observers do their duty without the top-level code having
# to interfere.
#
# Note that the contract between publisher and subscriber (observable and
# observer) is not declared or enforced.  The +Ticker+ publishes a time and a
# price, and the warners receive that.  But if you don't ensure that your
# contracts are correct, nothing else can warn you.
#
#   require "observer"
#
#   class Ticker          ### Periodically fetch a stock price.
#     include Observable
#
#     def initialize(symbol)
#       @symbol = symbol
#     end
#
#     def run
#       lastPrice = nil
#       loop do
#         price = Price.fetch(@symbol)
#         print "Current price: #{price}\n"
#         if price != lastPrice
#           mark_changed                 # notify observers
#           lastPrice = price
#           notify_observers(Time.now, price)
#         end
#         sleep 1
#       end
#     end
#   end
#
#   class Price           ### A mock class to fetch a stock price (60 - 140).
#     def Price.fetch(symbol)
#       60 + rand(80)
#     end
#   end
#
#   class Warner          ### An abstract observer of Ticker objects.
#     def initialize(ticker, limit)
#       @limit = limit
#       ticker.add_eventful_observer(self)
#     end
#   end
#
#   class WarnLow < Warner
#     def observable_changed(time, price)       # callback for observer
#       if price < @limit
#         print "--- #{time.to_s}: Price below #@limit: #{price}\n"
#       end
#     end
#   end
#
#   class WarnHigh < Warner
#     def observable_changed(time, price)       # callback for observer
#       if price > @limit
#         print "+++ #{time.to_s}: Price above #@limit: #{price}\n"
#       end
#     end
#   end
#
#   ticker = Ticker.new("MSFT")
#   WarnLow.new(ticker, 80)
#   WarnHigh.new(ticker, 120)
#   ticker.run
#
# Produces:
#
#   Current price: 83
#   Current price: 75
#   --- Sun Jun 09 00:10:25 CDT 2002: Price below 80: 75
#   Current price: 90
#   Current price: 134
#   +++ Sun Jun 09 00:10:25 CDT 2002: Price above 120: 134
#   Current price: 134
#   Current price: 112
#   Current price: 79
#   --- Sun Jun 09 00:10:25 CDT 2002: Price below 80: 79


#
# Implements the Observable design pattern as a mixin so that other objects can
# be notified of changes in state.  See observer.rb for details and an example.
#
module Eventful

  module Observable

    #
    # Add +observer+ as an observer on this object. +observer+ will now receive
    # notifications.
    #
    def add_eventful_observer(observer)
      @eventful_observer_peers = [] unless defined? @eventful_observer_peers
      unless observer.respond_to? :observable_changed
        raise NoMethodError, "observer needs to respond to `observable_changed'"
      end
      @eventful_observer_peers.push observer
    end

    #
    # Delete +observer+ as an observer on this object. It will no longer receive
    # notifications.
    #
    def delete_eventful_observer(observer)
      @eventful_observer_peers.delete observer if defined? @eventful_observer_peers
    end

    #
    # Delete all observers associated with this object.
    #
    def delete_eventful_observers
      @eventful_observer_peers.clear if defined? @eventful_observer_peers
    end

    #
    # Return the number of observers associated with this object.
    #
    def count_eventful_observers
      if defined? @eventful_observer_peers
        @eventful_observer_peers.size
      else
        0
      end
    end

    #
    # Set the changed state of this object.  Notifications will be sent only if
    # the changed +state+ is +true+.
    #
    def mark_changed(state=true)
      @eventful_observer_state = state
    end

    #
    # Query the changed state of this object.
    #
    def marked_changed?
      if defined? @eventful_observer_state and @eventful_observer_state
        true
      else
        false
      end
    end

    #
    # If this object's changed state is +true+, invoke the
    # +observable_changed+ method in each currently associated observer in
    # turn, passing it the given arguments. The changed state is then set to
    # +false+.
    #
    def notify_observers(*args)
      if defined? @eventful_observer_state and @eventful_observer_state
        if defined? @eventful_observer_peers
          for i in @eventful_observer_peers.dup
            i.observable_changed(*args)
          end
        end
        @eventful_observer_state = false
      end
    end

  end

end
