// Place any global data in this file.
// You can import this data from anywhere in your site by using the `import` keyword.

interface SocialLink {
  href: string;
  label: string;
}

interface Site {
  website: string;
  author: string;
  authorFullName: string;
  profile: string;
  desc: string;
  title: string;
  ogImage: string;
  lightAndDarkMode: boolean;
  postPerIndex: number;
  postPerPage: number;
  scheduledPostMargin: number;
  showArchives: boolean;
  showBackButton: boolean;
  editPost: {
    enabled: boolean;
    text: string;
    url: string;
  };
  dynamicOgImage: boolean;
  lang: string;
  timezone: string;
}

// Site configuration
export const SITE: Site = {
  website: "https://justcarlson.com/",
  author: "Justin Carlson",
  authorFullName: "Justin Carlson",
  profile: "https://justcarlson.com/about",
  desc: "Writing about things I find interesting.",
  title: "Justin Carlson",
  ogImage: "og.png",
  lightAndDarkMode: true,
  postPerIndex: 10,
  postPerPage: 10,
  scheduledPostMargin: 15 * 60 * 1000,
  showArchives: false,
  showBackButton: false,
  editPost: {
    enabled: true,
    text: "Edit on GitHub",
    url: "https://github.com/justcarlson/justcarlson.com/edit/main/",
  },
  dynamicOgImage: true,
  lang: "en",
  timezone: "America/Los_Angeles",
};

export const SITE_TITLE = SITE.title;
export const SITE_DESCRIPTION = SITE.desc;

// Navigation links
export const NAV_LINKS: SocialLink[] = [
  {
    href: "/",
    label: "Blog",
  },
  {
    href: "/about",
    label: "About",
  },
];

// Social media links
export const SOCIAL_LINKS: SocialLink[] = [
  {
    href: "https://github.com/justcarlson",
    label: "GitHub",
  },
  {
    href: "https://x.com/_justcarlson",
    label: "X",
  },
  {
    href: "https://www.linkedin.com/in/justincarlson0/",
    label: "LinkedIn",
  },
  {
    href: "/rss.xml",
    label: "RSS",
  },
];

// Icon map for social media
export const ICON_MAP: Record<string, string> = {
  GitHub: "github",
  X: "twitter",
  LinkedIn: "linkedin",
  RSS: "rss",
};

// Newsletter configuration
export const NEWSLETTER_CONFIG = {
  enabled: false,
  provider: "", // Set when newsletter service is configured (e.g., "buttondown", "convertkit")
  formAction: "", // Newsletter provider form action URL
  tag: "", // Optional tag for subscriber segmentation
};
