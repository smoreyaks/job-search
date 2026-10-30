import { JobListing } from './models';

// Ten fixed fake search results for working on the UI without spending JSearch
// quota. The Search page's "Dummy jobs" button shows them; nothing is fetched.
// The mix covers the cases the cards need to handle: salary or N/A, a missing
// location, long titles and long locations.
type DummySeed = Pick<JobListing, 'job_title' | 'company' | 'location' | 'salary_range' | 'employment_type' | 'remote_type'>;

// Publisher names as JSearch reports them, rotated across the dummies.
const BOARDS = ['LinkedIn', 'SEEK', 'Indeed', 'Glassdoor', 'Jora'];

const SEEDS: DummySeed[] = [
  { job_title: 'Web Developer', company: 'Acme Digital', location: 'Brisbane, QLD, AU', salary_range: 'N/A', employment_type: 'full-time', remote_type: 'hybrid' },
  { job_title: 'Senior Frontend Developer', company: 'Blue Fern Studio', location: 'Sydney, NSW, AU', salary_range: 'AUD 110,000–130,000 / year', employment_type: 'full-time', remote_type: 'on-site' },
  { job_title: 'Junior Full Stack Developer (Angular / Rails)', company: 'Harbourline Software', location: 'Melbourne, VIC, AU', salary_range: 'N/A', employment_type: 'full-time', remote_type: 'remote' },
  { job_title: 'Web Developer – Contract', company: 'Gumtree Analytics', location: 'Perth, WA, AU', salary_range: 'AUD 85–95 / hour', employment_type: 'contract', remote_type: 'remote' },
  { job_title: 'WordPress Developer', company: 'Saltwater Creative', location: null, salary_range: 'N/A', employment_type: 'part-time', remote_type: 'remote' },
  { job_title: 'Front End Engineer', company: 'Koala Payments', location: 'Gold Coast, QLD, AU', salary_range: 'AUD 95,000–105,000 / year', employment_type: 'full-time', remote_type: 'hybrid' },
  { job_title: 'Graduate Web Developer', company: 'Northstar Health', location: 'Adelaide, SA, AU', salary_range: 'N/A', employment_type: 'full-time', remote_type: 'on-site' },
  { job_title: 'Senior Software Engineer, Customer Experience Platform and Integrations', company: 'Redgum Logistics Group International', location: 'Parramatta, Western Sydney, NSW, AU', salary_range: 'AUD 140,000–160,000 / year', employment_type: 'full-time', remote_type: 'hybrid' },
  { job_title: 'React Developer', company: 'Tidal Labs', location: 'Hobart, TAS, AU', salary_range: 'N/A', employment_type: 'casual', remote_type: 'remote' },
  { job_title: 'Web Developer (Shopify)', company: 'Little Wattle Co.', location: 'Canberra, ACT, AU', salary_range: 'AUD 70,000 / year', employment_type: 'full-time', remote_type: 'on-site' },
];

export const DUMMY_JOBS: JobListing[] = SEEDS.map((seed, i) => ({
  ...seed,
  board_source: BOARDS[i % BOARDS.length],
  job_posted_date: '2026-10-20',
  hourly_rate: 'N/A',
  job_description:
    `Dummy listing ${i + 1} for UI work. ${seed.company} is looking for a ${seed.job_title} to build and maintain ` +
    'customer-facing web applications, work with designers on new features, and keep the codebase tidy and well tested.',
  url: `https://example.com/dummy-job-${i + 1}`,
  application_url: null,
  posted_by: null,
  poster_contact_number: null,
  poster_email: null,
  status: 'active',
  joe_status: 0,
  archived_at: null,
  jsearch_job_id: null,
}));
