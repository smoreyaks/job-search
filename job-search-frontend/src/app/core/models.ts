// TypeScript interfaces matching the Rails API JSON (snake_case, used as-is).

export interface JobListing {
  id?: number;
  board_source: string;
  company: string;
  job_title: string;
  location: string | null;
  job_posted_date: string;
  employment_type: string;
  remote_type: string;
  salary_range: string;
  hourly_rate: string;
  job_description: string;
  url: string;
  application_url: string | null;
  posted_by: string | null;
  poster_contact_number: string | null;
  poster_email: string | null;
  date_saved?: string;
  status: string;
  joe_status: number;
  archived_at: string | null;
  jsearch_job_id?: string | null;
  job_offer_expires_at?: string | null;
  // The Jobs API's (jobs-api14, LinkedIn) own id; set on jobs found through it.
  jobs_api_job_id?: string | null;
}

// The job APIs the Search page can search, matching /jobs/search's `source`.
// Each one is its own job pool; JSearch stays for when it serves Australia again.
export type JobSource = 'jsearch' | 'jobs_api';

export const JOB_SOURCES: { value: JobSource; label: string; description: string }[] = [
  { value: 'jobs_api', label: 'Jobs API', description: 'Jobs API: LinkedIn listings' },
  { value: 'jsearch', label: 'JSearch', description: 'JSearch: Google for Jobs listings' },
];

// The Search page's country selector; the API turns the code into each job
// source's own country filter.
export type Country = 'au' | 'us';

export const COUNTRIES: { value: Country; label: string }[] = [
  { value: 'au', label: 'Australia' },
  { value: 'us', label: 'USA' },
];

export interface Resume {
  id: number;
  file_name: string;
  date_uploaded: string;
  version_note: string;
  file_path: string;
  extracted_text: string | null;
  archived_at: string | null;
}

export interface CoverLetter {
  id: number;
  file_name: string;
  date_uploaded: string;
  version_note: string;
  file_path: string;
  archived_at: string | null;
}

export interface ComparisonResult {
  id: number | null;
  resume_id: number | null;
  job_listing_id: number | null;
  match_score: number;
  resume_suggestions: string | null;
  comparison_datetime: string | null;
}

export interface TrackingEntry {
  id: number;
  job_listing_id: number;
  resume_id: number;
  comparison_id: number;
  cover_letter_id: number;
  applied: boolean;
  date_applied: string | null;
  response_received: boolean;
  follow_up_needed: boolean;
  interview_date: string | null;
  notes: string | null;
  next_follow_up_date: string | null;
}

// The mark-as-dead toggle's values: 2 = manually dead, 1 = un-marked (back to
// expired, never to good). Saved through the Tracking save paths.
export type ManualJoeStatus = 1 | 2;

// A Tracking row's pending edits: its own fields plus, optionally, the toggle
// for its job (the backend writes that to the job listing).
export type TrackingChanges = Partial<TrackingEntry> & { joe_status?: ManualJoeStatus };

export interface AppConfig {
  id: number;
  local_app_data: string;
  delimiter: string;
  compare_prompt: string | null;
}

export interface DuplicateWarning {
  candidate_url: string;
  likely_match: JobListing;
}

export interface SaveAllResponse {
  saved: JobListing[];
  warnings: DuplicateWarning[];
}

export interface RefreshListingsResponse {
  listings: JobListing[];
  checked: number;
}

export interface SaveApplicationResponse {
  comparison: ComparisonResult;
  tracking: TrackingEntry;
}
