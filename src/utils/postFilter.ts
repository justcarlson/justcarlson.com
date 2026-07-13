import type { CollectionEntry } from "astro:content";
import { SITE } from "@/config";
import { isDraftPreview, isVisibleInBuild } from "./postVisibility";

const postFilter = ({ data }: CollectionEntry<"blog">) => {
  const isPublishTimePassed =
    Date.now() > new Date(data.pubDatetime).getTime() - SITE.scheduledPostMargin;
  return isVisibleInBuild(data) && !data.unlisted && (isDraftPreview || isPublishTimePassed);
};

export default postFilter;
