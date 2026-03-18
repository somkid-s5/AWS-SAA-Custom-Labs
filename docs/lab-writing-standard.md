# Lab Writing Standard

Use this structure for every lab in `labs/`:

1. `Business Scenario`
- Make it specific to the service family and the problem the lab is solving.
- Mention the failure mode, performance need, security constraint, or cost trade-off that motivates the design.

2. `CLI Commands`
- Include real AWS CLI commands whenever possible.
- Keep commands close to the actions the learner will actually run.

3. `Target Architecture`
- Draw the topology for that exact lab.
- Keep the diagram aligned with the services in the lab and avoid using the same generic graph everywhere.

4. `Expected Output`
- Show what success looks like.
- Include status fields, key property values, or observable behavior.

5. `Failure Injection`
- Describe one concrete fault injection step.
- State what the learner should observe after the fault.

6. `Decision Trade-offs`
- Compare the main options for that topic.
- Focus on RTO, cost, operational burden, and the service fit.

7. `Common Mistakes`
- List the mistakes that people actually make for that specific topic.
- Avoid generic bullets that could apply to any AWS service.

8. `Exam Question`
- Include the answer, not just the question.
- Add a short rationale that explains why the answer is correct.

If a lab cannot yet be fully specialized, at minimum replace the shared placeholder scenario and the repeated diagram with topic-specific content first.

