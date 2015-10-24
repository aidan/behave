Feature: Issue #290: Call before/after_background_hooks when running backgrounds

  Provide environment hooks before_background and after_background to
  allow eg. caching of complicated backgrounds

  Background:
    Given a new working directory
    And a file named "features/steps/steps.py" with:
        """
        from behave import step

        @when('the system state is cached to {key}')
        def cache_set(context, key):
            print ('caching state for %s' % key)
        
        @when('the system state is restored from cache {key}')
        def cache_put(context, key):
            print ('caching state for %s' % key)

        @step('a background step')
        def background_step(context):
            print ('background_step')

        @step('{step_name} {type} is ok')
        @step('{step_name} {type} succeeds')
        def step_fails(context, step_name, type):
            print ('%s %s' % (step_name, type))
        """

  Scenario: 
    Given a file named "features/step_tree_caching.feature" with
        """
        Feature:

          Background:
            Given a background step

          Scenario: The first scenario
            When first step succeeds
            Then first check is ok

          Scenario: The second scenario
            When first step succeeds
            And second step succeeds
            Then second check is ok
        """
    When I run "behave -f plain --no-capture --super-cache features/step_tree_caching.feature"
    Then it should pass
    And the command output should contain:
        """
        background_step
        Given a background step ... passed
        first step
        When first step succeeds ... passed
        caching state for -3561532529679889876
        when the system state is cached to -3561532529679889876 ... passed
        first check
        Then first check is ok ... passed
        Scenario: The second scenario
        background_step
        Given a background step ... passed
        caching state for -3561532529679889876
        when the system state is restored from cache -3561532529679889876 ... passed
        second step
        And second step succeeds ... passed
        second check
        Then second check is ok ... passed
        """

  # Todo scenarios
  Scenario: cache with an and step in the run
