
## Overview

This document explains opinions and standards we should follow when evaluating or writing code.

## Purpose

**IMPORTANT: See INSTRUCTIONS.md for the complete workflow. This file contains coding standards only.**

I want you to review the changes in `DIFF.md`, which represent a changeset to our code in a feature branch. This code was obtained by running `git diff remotes/origin/main > DIFF.md`.

Please review the file `DIFF.md` in the CONTEXT folder. **Add comments directly in the source code files** (not in CONTEXT folder, but in the worktree root where the actual source files are located). Do not make changes to the code at all - only add comments.

Additionally, only suggest improvements for the code that is included in `DIFF.md`, do not suggest code fixes outside of that source code. It will not be considered.

**DO NOT create a REVIEW.md file. All feedback must be added as inline comments in the source code files.**

### Standards

1. Extract complex or related logic into helpers. Favor modularly so parts can be reused or changed later without impacting other parts of the program

Keep functions short and focused. Move parsing, formatting, and calculations into well-named helpers.
Best practice

Keep the nesting level of your functions to 3 or less. If your function has a need for more nested levels, consider refactoring your function into sub-functions.

// helpers/price.ts
export function formatUSD(cents: number) {
  return `$${(cents / 100).toFixed(2)}`;
}

// usage
const label = formatUSD(order.totalCents);

2. Avoid deep nesting; use guard clauses and early returns

Prefer returning early for invalid/edge cases. Use switch when it improves clarity.

function createUser(input: Input) {
  if (!input.email) return Err('Missing email');
  if (!isValid(input)) return Err('Invalid data');

  switch (input.role) {
    case 'admin': return createAdmin(input);
    case 'member': return createMember(input);
    default: return Err('Unknown role');
  }
}

3. Favor functional, immutable updates

Don’t mutate objects/arrays in place. Derive new values using spread, map, filter, etc.

// bad: items.push(x); user.name = '…'
const nextItems = [...items, newItem];
const nextUser  = { ...user, name: 'Ada' };
const active    = users.filter(u => u.active);


4. Prefer functional components over classes

Use hooks and modern React patterns. Avoid class components in new code.

// good
function Counter() {
  const [n, setN] = useState(0);
  return <button onClick={() => setN(n + 1)}>{n}</button>;
}


5. Keep components small; prefer composition over configuration

One responsibility per component. Avoid prop bloat by composing children.

// composition
<Card>
  <Card.Header>Title</Card.Header>
  <Card.Body>Content</Card.Body>
  <Card.Footer><Actions /></Card.Footer>
</Card>
// export style
export const Header = ({ children }: Props) => <h2>{children}</h2>;
export { Header as CardHeader };


6. Hook discipline: predictable effects and stable references

Never call hooks conditionally. Keep useEffect side-effect only, include all deps, and clean up.

function Search({ term }: { term: string }) {
  const ctrl = useRef<AbortController | null>(null);

  useEffect(() => {
    ctrl.current?.abort();
    ctrl.current = new AbortController();

    fetch(`/api?q=${term}`, { signal: ctrl.current.signal });
    return () => ctrl.current?.abort(); // cleanup
  }, [term]);

  const onSelect = useCallback((id: string) => {/* … */}, []); // stable
  return /* … */;
}


7. State: minimize, normalize, don’t duplicate

Keep a single source of truth. Derive instead of storing. Normalize collections by id.

type ById<T extends { id: string }> = Record<string, T>;
const usersById: ById<User> = Object.fromEntries(users.map(u => [u.id, u]));
const selectedUser = usersById[selectedId]; // derive, don’t mirror props in state


Treat async and errors as first-class

Use async/await. Always handle errors, timeouts, and cancellation. Show loading/error UI consistently.

async function getJSON<T>(url: string, signal?: AbortSignal): Promise<T> {
  const r = await fetch(url, { signal });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json() as Promise<T>;
}

8. Optimize with evidence

Use stable keys; memoize hot paths; virtualize long lists; code-split heavy routes/components.

const Item = React.memo(function Item({ item }: { item: Row }) {
  const onPress = useCallback(() => doThing(item.id), [item.id]);
  return <RowView key={item.id} onPress={onPress} item={item} />;
});

const Settings = React.lazy(() => import('./Settings')); // code-split
