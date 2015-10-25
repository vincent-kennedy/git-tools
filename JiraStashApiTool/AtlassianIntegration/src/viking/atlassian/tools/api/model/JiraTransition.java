package viking.atlassian.tools.api.model;

/**
 * Request model for transitioning a JIRA issue.
 *
 * @author Andreas Borglin
 */
public class JiraTransition {

    public static class Transition {
        private String id;

        public String getId() {
            return id;
        }

        public void setId(String id) {
            this.id = id;
        }
    }

    private Transition transition;

    public JiraTransition() {
    }

    public JiraTransition(String id) {
        transition = new Transition();
        transition.setId(id);
    }

    public Transition getTransition() {
        return transition;
    }

    public void setTransition(Transition transition) {
        this.transition = transition;
    }
}
