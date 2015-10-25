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
            print ('restoring state from %s' % key)

        @step('a background step')
        def background_step(context):
            print ('background_step')

        @step('{step_name} {type} is ok')
        @step('{step_name} {type} succeeds')
        def step_fails(context, step_name, type):
            print ('%s %s' % (step_name, type))
        """

  Scenario: Cache background and common 1st step
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
            Then first check is ok
            And second check is ok
        """
    When I run "behave -f plain --no-capture --super-cache features/step_tree_caching.feature"
    Then it should pass
    And the command output should contain:
    """
      Scenario: The first scenario
    background_step
        Given a background step ... passed
    first step
        When first step succeeds ... passed
    caching state for -3561532529679889876
        when the system state is cached to -3561532529679889876 ... passed
    first check
        Then first check is ok ... passed
      
      Scenario: The second scenario
        Given a background step ... skipped
        When first step succeeds ... skipped
    restoring state from -3561532529679889876
        when the system state is restored from cache -3561532529679889876 ... passed
    second step
        And second step succeeds ... passed
    first check
        Then first check is ok ... passed
    second check
        And second check is ok ... passed
    """

  Scenario: Scenarios with an and step right after the cacheable step but not a when
    Given a file named "features/step_tree_caching.feature" with
        """
        Feature:

          Background:
            Given a background step

          Scenario: The first scenario
            Given first step succeeds
            When second step succeeds
            Then first check is ok

          Scenario: The second scenario
            Given first step succeeds
            And second step succeeds
            When third step succeeds
            Then first check is ok
        """
    When I run "behave -f plain --no-capture --super-cache features/step_tree_caching.feature"
    Then it should pass
    And the command output should contain:
    """
      Scenario: The first scenario
    background_step
        Given a background step ... passed
    first step
        Given first step succeeds ... passed
    caching state for 3390203783646515014
        when the system state is cached to 3390203783646515014 ... passed
    second step
        When second step succeeds ... passed
    first check
        Then first check is ok ... passed
      
      Scenario: The second scenario
        Given a background step ... skipped
        Given first step succeeds ... skipped
    restoring state from 3390203783646515014
        when the system state is restored from cache 3390203783646515014 ... passed
    second step
        And second step succeeds ... passed
    third step
        When third step succeeds ... passed
    first check
        Then first check is ok ... passed
    """
    
  Scenario: feature file with no background  
    Given a file named "features/step_tree_caching.feature" with
        """
        Feature:

          Scenario: The first scenario
            Given first step succeeds
            When second step succeeds
            Then first check is ok

          Scenario: The second scenario
            Given first step succeeds
            When third step succeeds
            Then fourth check is ok
        """
    When I run "behave -f plain --no-capture --super-cache features/step_tree_caching.feature"
    Then it should pass
    And the command output should contain:
    """
      Scenario: The first scenario
    first step
        Given first step succeeds ... passed
    caching state for 3390203783646515014
        when the system state is cached to 3390203783646515014 ... passed
    second step
        When second step succeeds ... passed
    first check
        Then first check is ok ... passed
      
      Scenario: The second scenario
        Given first step succeeds ... skipped
    restoring state from 3390203783646515014
        when the system state is restored from cache 3390203783646515014 ... passed
    third step
        When third step succeeds ... passed
    fourth check
        Then fourth check is ok ... passed
    """

  Scenario: feature file with mulitple common steps
    Given a file named "features/step_tree_caching.feature" with
        """
        Feature:

          Scenario: The first scenario
            Given first step succeeds
            When second step succeeds
            Then first check is ok

          Scenario: The second scenario
            Given first step succeeds
            When second step succeeds
            And third step succeeds
            Then first check is ok
        """
    When I run "behave -f plain --no-capture --super-cache features/step_tree_caching.feature"
    Then it should pass
    And the command output should contain:
    """
        Scenario: The first scenario
      first step
          Given first step succeeds ... passed
      second step
          When second step succeeds ... passed
      caching state for 2886626038487129819
          when the system state is cached to 2886626038487129819 ... passed
      first check
          Then first check is ok ... passed
      
        Scenario: The second scenario
          Given first step succeeds ... skipped
          When second step succeeds ... skipped
      restoring state from 2886626038487129819
          when the system state is restored from cache 2886626038487129819 ... passed
      third step
          And third step succeeds ... passed
      first check
          Then first check is ok ... passed
    """

  Scenario: feature file with mulitple sets of common steps out of order
    Given a file named "features/step_tree_caching.feature" with
        """
        Feature:

          Scenario: The first scenario
            Given first step succeeds
            And second step succeeds
            When third step succeeds
            Then fourth check is ok

          Scenario: The second scenario
            Given first step succeeds
            And second step succeeds
            When third step succeeds
            And fourth step succeeds
            Then fifth check is ok

          Scenario: The third scenario
            Given first step succeeds
            When second step succeeds
            Then third check is ok

        """
    When I run "behave -f plain --no-capture --super-cache features/step_tree_caching.feature"
    Then it should pass
    And the command output should contain:
    """
        Scenario: The first scenario
      first step
          Given first step succeeds ... passed
      caching state for 3390203783646515014
          when the system state is cached to 3390203783646515014 ... passed
      second step
          And second step succeeds ... passed
      third step
          When third step succeeds ... passed
      caching state for 3340107766547310146
          when the system state is cached to 3340107766547310146 ... passed
      fourth check
          Then fourth check is ok ... passed
      
        Scenario: The second scenario
          Given first step succeeds ... skipped
          And second step succeeds ... skipped
          When third step succeeds ... skipped
      restoring state from 3340107766547310146
          when the system state is restored from cache 3340107766547310146 ... passed
      fourth step
          And fourth step succeeds ... passed
      fifth check
          Then fifth check is ok ... passed
      
        Scenario: The third scenario
          Given first step succeeds ... skipped
      restoring state from 3390203783646515014
          when the system state is restored from cache 3390203783646515014 ... passed
      second step
          When second step succeeds ... passed
      third check
          Then third check is ok ... passed
    """
    
  # Scenario: feature file scenario with background but no common step
