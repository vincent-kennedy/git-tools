package viking.atlassian.tools.api.model;

/**
 * Pull request response model.
 * @author Andreas Borglin
 */
public class PullRequestResponse {

    public static class Link {
        private String url;

        public String getUrl() {
            return url;
        }

        public void setUrl(String url) {
            this.url = url;
        }
    }

    private String id;
    private Link link;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public Link getLink() {
        return link;
    }

    public void setLink(Link link) {
        this.link = link;
    }

}
