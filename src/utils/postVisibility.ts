type PostVisibilityData = {
  draft?: boolean;
};

/**
 * Drafts are rendered locally and in Vercel Preview deployments, but never in
 * the production deployment. This gives draft branches a private review URL.
 */
export const isDraftPreview = import.meta.env.DEV || process.env.VERCEL_ENV === "preview";

export const isVisibleInBuild = ({ draft }: PostVisibilityData) => !draft || isDraftPreview;
