# Contributing to sdlc-kit

Thanks for helping. The kit's whole idea is that scripts, not the model, decide when work is done, so changes to the
kit follow the same rule.

## Ground rules

1. **Keep every rule and skill short.** Cheap models skip long instructions. Put a new rule in the file that loads only
   when it's needed (a scoped standards file or a phase skill), not in the always-on rules.
2. **Add a rule only after you've seen an agent make the same mistake twice.** Describe the mistake in the PR, with a
   transcript snippet if you have one.
3. **Changing a check script or the hook?** Add a self-test case, and show that it fails against the old version of the
   script. A test that can't fail proves nothing.
4. **Run the self-test before you open a PR:**
   ```bash
   bash .cursor/skills/run-checks/scripts/selftest.sh   # must end with ALL OK
   ```

## The most valuable issue you can open

A way to get `ALL PASS` on a bad change, or to slip a blocked command past the hook. Include the exact commands to
reproduce it. We'll turn it into a self-test case.

## Good first contributions

- Support for another stack: a standards file plus changes to `check_backend.sh` or `check_frontend.sh`
- A GitHub (`gh`) version of the MR skills
- Wording fixes for steps an agent actually skipped (show where it went wrong)
- Anything on the [roadmap](README.md#roadmap)

## Style

Plain, short sentences in the skills, numbered steps, and one `Verify` line where a step can be checked. Match the
surrounding scripts: `set -uo pipefail`, quoted variables, and output that says what failed and what to do next.
