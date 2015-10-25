package viking.atlassian.tools.api;

import viking.atlassian.tools.api.model.PullRequest;
import viking.atlassian.tools.api.model.PullRequestResponse;
import retrofit.http.*;

/**
 * Stash REST API service.
 * @author Andreas Borglin
 */
public interface StashService {

    @POST("/projects/{projectKey}/repos/{repoSlug}/pull-requests")
    PullRequestResponse createPullRequest(@Header("Authorization") String authorization, @Path("projectKey") String projectKey, @Path("repoSlug") String repoSlug, @Body PullRequest pullRequest);
}
