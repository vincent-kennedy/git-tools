package viking.atlassian.tools.api;

import viking.atlassian.tools.api.model.PullRequest;

/**
 * General API helper stuff.
 * @author Andreas Borglin
 */
public class ApiHelper {

    private static final String REF_HEADS = "refs/heads/";

    public static PullRequest.Ref createPullRequestRef(String branch, String repoSlug, String projectKey) {
        PullRequest.Repository repository = new PullRequest.Repository(repoSlug, "", projectKey);
        PullRequest.Ref ref = new PullRequest.Ref(REF_HEADS + branch, repository);
        return ref;
    }
}
