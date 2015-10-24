from model import Step
import pprint
pp = pprint.PrettyPrinter(indent=4)

def super_cache_parser(features):
    # Build a map of the suite, identifying any common runs
    step_counts = {}

    for feature in features:
        for scenario in feature.scenarios:
            step_tree = []
            for i, step in enumerate(scenario.steps):
                step_key = (step.step_type + step.name + str(hash(step.text)) + str(hash(step.table)))
                step_tree.append(step_key)
                step_index = hash(''.join(step_tree))
                item = (scenario, i)
                if step_index in step_counts:
                    step_counts[step_index].append(item)
                else:
                    step_counts[step_index] = [item]

    # Modify the steps that common runs to execute the 1st instance
    # and replace any further ones with cache restores of the right
    # key
    for index, runs in step_counts.items():
        if len(runs) > 1:
            # Add a cache step to the first scenario
            cache_step = Step(u"", u"", u"when", u"when", u"the system state is cached to %s" % index)
            first_scenario, step_index = runs.pop(0)

            first_scenario.steps.insert(step_index, cache_step)

            # Replace the tree in subsequent scenarios up to this point with a cache restore
            restore_step = Step(u"", u"", u"when", u"when", u"the system state is restored from cache %s" % index)
            for other_scenario, step_index in runs:
                other_scenario.steps = [restore_step] + other_scenario.steps[step_index+1:]
    return features
