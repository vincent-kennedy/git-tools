package viking.atlassian.tools.api.model;

import java.util.List;

/**
 * Response objects for available JIRA issue transitions.
 *
 * @author Andreas Borglin
 */
public class JiraTransitionsResponse {

    private static final String START_REVIEW_TRANSITION = "Start Review";
    private static final String MARK_AS_DONE_TRANSITION = "Done";
    private static final String MARK_AS_RESOLVED_TRANSITION = "Resolve Issue";

    public static class Transition {
        private String id;
        private String name;

        public String getId() {
            return id;
        }

        public void setId(String id) {
            this.id = id;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }
    }

    private List<Transition> transitions;

    public List<Transition> getTransitions() {
        return transitions;
    }

    public void setTransitions(List<Transition> transitions) {
        this.transitions = transitions;
    }

    public String getStartReviewTransitionId() {
        for (Transition transition : transitions) {
            if (transition.getName().equals(START_REVIEW_TRANSITION)) {
                return transition.getId();
            }
        }
        return null;
    }

    public String getCompletedTransitionId() {
        for (Transition transition : transitions) {
            if (transition.getName().equals(MARK_AS_DONE_TRANSITION) || transition.getName().equals(MARK_AS_RESOLVED_TRANSITION)) {
                return transition.getId();
            }
        }
        return null;
    }

    public String getTransitionNameFromId(String id) {
        for (Transition transition : transitions) {
            if (transition.getId().equals(id)) {
                return transition.getName();
            }
        }
        return "Unknown";
    }
}
