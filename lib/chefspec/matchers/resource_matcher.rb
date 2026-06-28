require "rspec/expectations/fail_with"

module ChefSpec::Matchers
  class ResourceMatcher
    def initialize(resource_name, expected_action, expected_identity)
      @resource_name     = resource_name
      @expected_action   = expected_action
      @expected_identity = expected_identity
    end

    def with(parameters = {})
      params.merge!(parameters)
      self
    end

    def at_compile_time
      raise ArgumentError, "Cannot specify both .at_converge_time and .at_compile_time!" if @converge_time

      @compile_time = true
      self
    end

    def at_converge_time
      raise ArgumentError, "Cannot specify both .at_compile_time and .at_converge_time!" if @compile_time

      @converge_time = true
      self
    end

    #
    # Allow users to specify fancy #with matchers.
    #
    def method_missing(m, *args, &block)
      if m.to_s =~ /^with_(.+)$/
        with($1.to_sym => args.first)
        self
      else
        super
      end
    end

    def description
      %Q{#{@expected_action} #{@resource_name} "#{@expected_identity}"}
    end

    def matches?(runner)
      @runner = runner

      if resource
        ChefSpec::Coverage.cover!(resource)
        unmatched_parameters.empty? && correct_phase?
      end
    end

    def failure_message
      if resource
        if unmatched_parameters.empty?
          if @compile_time
            %Q{expected "#{resource}" to be run at compile time}
          else
            %Q{expected "#{resource}" to be run at converge time}
          end
        else
          message = %Q{expected "#{resource}" to have parameters:} \
            "\n\n" \
            "  " + unmatched_parameters.collect { |parameter, h|
              msg = "#{parameter} #{h[:expected].inspect}, was #{h[:actual].inspect}"
              diff = diff_for(h[:expected], h[:actual], message)
              msg += diff if diff
              msg
            }.join("\n  ")
        end
      else
        %Q{expected "#{@resource_name}[#{@expected_identity}]"} \
          " with action :#{@expected_action} to be in Chef run." \
          " Other #{@resource_name} resources:" \
          "\n\n" \
          "  " + similar_resources.map(&:to_s).join("\n  ") + "\n "
      end
    end

    def failure_message_when_negated
      if resource
        message = %Q{expected "#{resource}" actions #{resource.performed_actions.inspect} to not exist}
      else
        message = %Q{expected "#{resource}" to not exist}
      end

      message << " at compile time"  if @compile_time
      message << " at converge time" if @converge_time
      message
    end

    private

    #
    # Build the diff text for a mismatched parameter using rspec-expectations'
    # private diff helper. That helper was renamed and its signature changed in
    # rspec-expectations 3.12.4 (`ExpectedsForMultipleDiffs.from(expected)` with
    # `message_with_diff(message, differ, actual)` became
    # `MultiMatcherDiff.from(expected, actual)` with
    # `message_with_diff(message, differ)`), so support both shapes.
    #
    # @return [String, nil]
    #
    def diff_for(expected, actual, message)
      differ = ::RSpec::Expectations.differ
      if defined?(::RSpec::Matchers::MultiMatcherDiff)
        ::RSpec::Matchers::MultiMatcherDiff.from(expected, actual)
          .message_with_diff(message, differ)
      else
        ::RSpec::Matchers::ExpectedsForMultipleDiffs.from(expected)
          .message_with_diff(message, differ, actual)
      end
    end

    def unmatched_parameters
      return @_unmatched_parameters if @_unmatched_parameters

      @_unmatched_parameters = {}

      params.each do |parameter, expected|
        unless matches_parameter?(parameter, expected)
          @_unmatched_parameters[parameter] = {
            expected: expected,
            actual: safe_send(parameter),
          }
        end
      end

      @_unmatched_parameters
    end

    def matches_parameter?(parameter, expected)
      value = safe_send(parameter)
      if parameter == :source
        # Chef 11+ stores the source parameter internally as an Array
        Array(expected) == Array(value)
      elsif expected.is_a?(Class)
        # Ruby can't compare classes with ===
        expected == value
      else
        expected === value
      end
    end

    def correct_phase?
      if @compile_time
        resource.performed_action(@expected_action)[:compile_time]
      elsif @converge_time
        resource.performed_action(@expected_action)[:converge_time]
      else
        true
      end
    end

    def safe_send(parameter)
      resource.send(parameter)
    rescue NoMethodError
      nil
    end

    #
    # Any other resources in the Chef run that have the same resource
    # type. Used by {failure_message} to be ultra helpful.
    #
    # @return [Array<Chef::Resource>]
    #
    def similar_resources
      @_similar_resources ||= @runner.find_resources(@resource_name)
    end

    #
    # Find the resource in the Chef run by the given class name and
    # resource identity/name.
    #
    # @see ChefSpec::SoloRunner#find_resource
    #
    # @return [Chef::Resource, nil]
    #
    def resource
      @_resource ||= @runner.find_resource(@resource_name, @expected_identity, @expected_action)
    end

    #
    # The list of parameters passed to the {with} matcher.
    #
    # @return [Hash]
    #
    def params
      @_params ||= {}
    end
  end
end
