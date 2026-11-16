# Follow-up tickets carry their own content

Narrows ADR 0002. A ticket deferred from the follow-up sort has no spec to
point at, so its body (what, why it matters, where it was found, acceptance
criteria) is its content, held on the tracker. We accept this because such
tickets are small, written once with full context at finishing, and ADR 0002's
truncation risk came from large spec bodies. A committed note per follow-up
was rejected: it would be committed on the feature branch mid-task and stay
invisible to other sessions until merge. Spec tickets are unchanged: content in
the spec file, the ticket points at it. A follow-up that grows past a ticket
goes through brainstorming and gets a spec like any other work.
