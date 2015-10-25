package viking.atlassian.tools.param;

import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;

/**
 * Command for transitioning JIRA issues.
 * @author Andreas Borglin
 */
@Parameters(commandDescription = "Transition JIRA issue", separators = "=")
public class TransitionIssueCommand {

    public static final String TAG = "transitionIssue";
    public static final String TRANSITION_START_REVIEW = "startReview";
    public static final String TRANSITION_COMPLETED = "completed";

    @Parameter(names = "--topicBranch")
    private String topicBranch;

    @Parameter(names = "--destBranch")
    private String destBranch;

    @Parameter(names = "--transition")
    private String transition;

    @Parameter(names = "--baseCommit")
    private String baseCommit;

    @Parameter(names = "--debug", arity = 1)
    private boolean debug = false;

    public String getTopicBranch() {
        return topicBranch;
    }

    public String getDestBranch() {
        return destBranch;
    }

    public String getTransition() {
        return transition;
    }

    public String getBaseCommit() {
        return baseCommit;
    }

    public boolean isDebug() {
        return debug;
    }
}
