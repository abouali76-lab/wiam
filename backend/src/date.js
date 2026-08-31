// Calendar date in a given IANA timezone, as "YYYY-MM-DD" — this is the key
// every TaskCompletion row is scoped to, so "today" always means "today
// where the child's device is," not the server's local date.
function todayInTimezone(timezone) {
  return new Intl.DateTimeFormat("en-CA", { timeZone: timezone }).format(new Date());
}

module.exports = { todayInTimezone };
