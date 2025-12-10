# DIFF_STANDARDS.md

## ⚠️ IMPORTANT WORKFLOW NOTE

**This file contains review guidelines and standards for reference.**

**However, the actual workflow is defined in INSTRUCTIONS.md:**
- **DO NOT create a REVIEW.md file**
- **Add comments directly to source code files** (not summary documents)
- **Read INSTRUCTIONS.md first** to understand the complete workflow

The standards below should guide your review, but all feedback must be embedded as inline comments in the actual source code files.

---

## Overview
This document sets the context for reviewing a `DIFF.md` file generated from a `git diff` or pull request comparison.
The goal is to ensure the assistant provides a structured, insightful, and high-signal review of code changes — identifying potential issues, improvements, and design implications.

---

## Context
- **Project type:** Full-stack TypeScript application (React Native + Express API)
- **Primary language:** TypeScript
- **Relevant framework/libraries:** Express, Drizzle ORM, Zod, React Native
- **Review focus:**
  - ✅ Code correctness / logical accuracy
  - ✅ Readability & maintainability
  - ✅ Performance / scalability
  - ✅ API design / type safety
  - ✅ Security / input validation
  - ✅ Architectural consistency
  - ✅ Style & conventions

---

## Assistant Goals
When reviewing the upcoming diff:
1. **Summarize** what the diff changes — functions, components, or files modified.
2. **Assess intent** — infer what problem the change is trying to solve.
3. **Evaluate** the changes based on the "Review Focus" categories above.
4. **Provide inline feedback** by quoting specific code sections and adding suggestions immediately after.
5. **Flag issues** using severity levels:
   - 🔴 **Critical:** likely causes bugs, crashes, or data loss
   - 🟠 **Major:** impacts performance, architecture, or maintainability
   - 🟡 **Minor:** style, readability, or non-breaking logic tweak
   - 🟢 **Nitpick:** preference-level improvements
6. **Recommend improvements** with code examples when appropriate.
7. **Summarize overall quality**, risk level, and readiness for merge.

---

## Critical Review Guidelines

### What to Review
- **ONLY review code that appears in the diff** - do not suggest changes to code that wasn't modified
- Focus on the changed lines and their immediate context
- Consider how changes impact existing functionality

### How to Provide Feedback
When you find an issue, use this format:

**File:** `path/to/file.ts`

**Issue:** 🟠 **[Severity Level] [Issue Title]**

```typescript
// Quote the exact code from the diff that has the issue
const problematicCode = doSomething();
```

**Suggestion:**
```typescript
// Show your improved version
const betterCode = doSomethingBetter();
```

**Explanation:** Explain WHY this change is needed and what problem it solves. Reference coding standards when applicable.

**Note:** Suggestions for fixes should be embedded directly as comments in the code files, placed immediately above the line that needs to be changed.

---

## Review Format (For Reference Only)

**IMPORTANT: Do NOT create a separate review document. The format below is for reference to guide your thinking, but all feedback must be added as inline comments in the source code files.**

The sections below describe how to think about and categorize issues, but you should embed these directly in code comments, not create a separate document.

### 🔍 Summary
A high-level summary of the diff — what was changed and why (inferred intent). Keep it concise (2-3 sentences).

---

### 📝 Detailed Review

For each file with issues, provide feedback in this format:

#### File: `path/to/file.ts`

**Change Summary:** Brief description of what changed in this file.

**Issue 1:** 🔴 **[Issue Title]**

```typescript
// Exact code from diff (include line numbers if significant)
const problematicCode = await fetchData();
return problematicCode.value;
```

**Suggestion:**
```typescript
const result = await fetchData();
if (!result) {
  throw new Error('Data fetch failed');
}
return result.value;
```

**Explanation:** The original code doesn't handle the case where `fetchData()` returns null/undefined, which will cause a runtime error. Always validate async results before accessing properties.

---

**Issue 2:** 🟡 **[Issue Title]**
[Continue same format for additional issues]

---

### 💡 Recommendations

Actionable items organized by priority:

#### Must Fix (Before Merge)
- [ ] Critical issue that needs immediate attention
- [ ] Security vulnerability that must be addressed

#### Should Fix (High Priority)
- [ ] Performance concern
- [ ] Missing error handling

#### Consider (Nice to Have)
- [ ] Code style improvement
- [ ] Refactoring opportunity

#### Testing Suggestions
- [ ] Missing test cases to add
- [ ] Edge cases to validate

---

### 🧾 Overall Assessment

| Category | Rating | Notes |
|-----------|---------|-------|
| Correctness | ✅ / ⚠️ / ❌ | Brief assessment |
| Readability | ✅ / ⚠️ / ❌ | Brief assessment |
| Performance | ✅ / ⚠️ / ❌ | Brief assessment |
| Security | ✅ / ⚠️ / ❌ | Brief assessment |
| Test Coverage | ✅ / ⚠️ / ❌ | Brief assessment |
| **Merge Readiness** | ✅ / ⚠️ / ❌ | **Final verdict** |

**Risk Level:** 🟢 Low / 🟡 Medium / 🔴 High

**Rationale:** 1-2 sentence explanation of the overall risk assessment and merge recommendation.

---

## Important Notes

### Do's ✅
- Quote specific code sections from the diff when providing feedback
- Explain the "why" behind each suggestion
- Reference project coding standards when relevant
- Provide code examples for suggested improvements
- Be specific and actionable
- Give positive feedback when code is done well

### Don'ts ❌
- Don't suggest changes to code that wasn't modified in the diff
- Don't be vague (e.g., "this could be better" without specifics)
- Don't over-format with excessive styling
- Don't assume malicious intent
- Don't nitpick without explaining the value of the change

### Scope Limits
- Only review files and lines that appear in the diff
- Focus on the changes and their immediate impact
- Consider downstream effects but don't audit the entire codebase
- If you notice broader architectural issues, mention them separately as "Notes for Future Work"

---

## Example Review

### 🔍 Summary
This diff adds a new `date` field to the CNR data response and fixes a bug where failed stops were incorrectly appearing in the ad-hoc stops array.

---

### 📝 Detailed Review

#### File: `src/services/dispatch/extract-manifests-data.ts`

**Change Summary:** Added early return after processing failed stops to prevent them from appearing in ad-hoc stops.

**Issue 1:** 🟢 **Good Fix - Logic Improvement**

```typescript
// Added code (lines 51-52)
//if the stop is failed, we don't need to process it any further.
return;
```

**Assessment:** ✅ This is a good fix! The early return correctly prevents failed stops from being processed as ad-hoc stops. The comment clearly explains the intent.

**Suggestion:** Minor style improvement for consistency:

```typescript
// If the stop is failed, we don't need to process it any further
return;
```

**Explanation:** Capitalize the first letter of the comment for consistency with coding standards.

---

**Issue 2:** 🟡 **Missing Type Safety**

```typescript
// Line 58 (not shown in full context)
if (!stop.recurringStopId) {
```

**Observation:** This logic correctly identifies ad-hoc stops, but there's no type guard to ensure `recurringStopId` is the right type.

**Suggestion:** If TypeScript types are loose here, consider adding a runtime check:

```typescript
if (!stop.recurringStopId || stop.recurringStopId === null) {
```

**Explanation:** Makes the null-check explicit, though this may be unnecessary if types are strict.

---

#### File: `src/routes/dispatch/endpoints/get-cnr-data.ts`

**Change Summary:** Added `date` field to response schema and data object.

**Issue 1:** ✅ **Good Addition**

The addition of the `date` field to both the Zod schema and response object is correct and well-tested. No issues found.

---

### 💡 Recommendations

#### Must Fix (Before Merge)
- None

#### Should Fix (High Priority)
- None

#### Consider (Nice to Have)
- [ ] Capitalize the comment in `extract-manifests-data.ts` line 51 for style consistency

#### Testing Suggestions
- ✅ Test coverage is excellent - all new functionality has corresponding tests

---

### 🧾 Overall Assessment

| Category | Rating | Notes |
|-----------|---------|-------|
| Correctness | ✅ | Logic fix is sound, date field added correctly |
| Readability | ✅ | Code is clear with helpful comments |
| Performance | ✅ | Early return improves efficiency slightly |
| Security | ✅ | No security concerns |
| Test Coverage | ✅ | Comprehensive test additions |
| **Merge Readiness** | ✅ | **Ready to merge** |

**Risk Level:** 🟢 Low

**Rationale:** This is a clean bug fix with good test coverage. The logic change correctly prevents failed stops from appearing in ad-hoc stops, and the date field addition is straightforward and well-validated.
