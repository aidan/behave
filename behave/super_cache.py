from copy import copy
from model import Step

def super_cache_parser(features):
    # Build a map of the suite, identifying any common runs
    step_counts = {}

    for feature in features:
        first_scenario = True
        for scenario in feature.scenarios:
            step_tree = []
            previous_run = None
            for i, step in enumerate(scenario.steps):
                step_key = (step.step_type + step.name + str(hash(step.text)) + str(hash(step.table)))
                step_tree.append(step_key)
                step_index = hash(''.join(step_tree))
                item = (scenario, i)
                if step_index in step_counts:
                    if previous_run:
                        step_counts[previous_run].pop(-1)
                    previous_run = step_index
                    step_counts[step_index].append(item)
                else:
                    step_counts[step_index] = [item]

            if scenario.background is not None:
                # Either cache or restore the background
                cache_key = hash(feature.filename)
                if first_scenario:
                    first_scenario = False
                    step = Step(u"", u"", u"when", u"when", u"the system state is cached to %s" % cache_key)
                    # Copy the background as we'll mark the others for skipping
                    scenario.background = copy(scenario.background)
                    scenario.steps.insert(0, step)
                else:
                    scenario.background.skip()
                    if not previous_run:
                        step = Step(u"", u"", u"when", u"when", u"the system state is restored from cache %s" % cache_key)
                        scenario.steps.insert(0, step)

    # Modify the steps that common runs to execute the 1st instance
    # and replace any further ones with cache restores of the right
    # key
    for cache_key, runs in step_counts.items():
        if len(runs) > 1:
            # Add a cache step to the first scenario at the right point
            cache_step = Step(u"", u"", u"when", u"when", u"the system state is cached to %s" % cache_key)
            first_scenario, step_index = runs.pop(0)
            offset = 1
            if first_scenario.background is not None:
                offset = 2
            # Step index will be off by one due to background caching
            first_scenario.steps.insert(step_index + offset, cache_step)

            # Remove the background cache restore, skip the steps in
            # subsequent scenarios up to the common point and add a
            # cache restore there
            restore_step = Step(u"", u"", u"when", u"when", u"the system state is restored from cache %s" % cache_key)
            for other_scenario, step_index in runs:
                for i in range(step_index + 1):
                    other_scenario.steps[i].skip()
                other_scenario.steps.insert(step_index + 1, restore_step)

    return features
