import { HttpErrorResponse } from '@angular/common/http';

// Turns any failure into one plain sentence: what couldn't be done, then why.
// `action` names the user's action, e.g. "Couldn't save the job". The API's own
// messages (422 validation, 502 JSearch/Gemini failures, 404) are already
// written for people, so they're shown as they come; everything else gets a
// plain explanation instead of a raw technical one.
export function describeError(err: unknown, action: string): string {
  return `${action}: ${reasonFor(err)}`;
}

function reasonFor(err: unknown): string {
  if (err instanceof HttpErrorResponse) {
    if (err.status === 0) {
      return "the app server isn't responding. Check that Rails is running on port 3001.";
    }
    const apiMessage = typeof err.error?.error === 'string' ? err.error.error.trim() : '';
    if (apiMessage && err.status < 500) return sentence(apiMessage);
    if (apiMessage && err.status === 502) return sentence(apiMessage);
    if (err.status >= 500) return 'something went wrong on the server. Try again, and check the Rails log if it keeps happening.';
    return sentence(apiMessage || `the server answered ${err.status}.`);
  }
  if (err instanceof Error && err.message) return sentence(err.message);
  return 'something unexpected went wrong.';
}

// Lower-cases the first letter so it reads on after "Couldn't …:", and ends
// with a full stop. Acronyms and names (JSearch, PDF) keep their capital.
function sentence(text: string): string {
  const trimmed = text.trim();
  const first = /^[A-Z][a-z]/.test(trimmed) ? trimmed[0].toLowerCase() + trimmed.slice(1) : trimmed;
  return /[.!?]$/.test(first) ? first : `${first}.`;
}
