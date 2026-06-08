We are working on building a skill creation harness.

This should become a factory that creates skills that are of production grade quality, benchmarked, autonomously improved, and verified and battle tested.

We build skills that survive the test of time.

We will use the following concepts, will elaborate.

@.agents/skills/autoresearch/SKILL.md for autonomous improvment based on rubrics -- which will also be useful in benchmarking

An agent harness that ships production grade code. 
So a doer, a verifier, a concensus reacher.

Whichever task we build needs to be verified and SCRUTINIZED thoroughly bo other agents that are not biased from the previous context.

We identify scores that we can measure against, and we autoresearch till we achieve the goal.

I have built all of this before, but all over the place. What we are doing now is creating a factory off of this.

For example:
In a prior production-grade skill build I built the skill @.agents/skills/production-grade/SKILL.md myself -- We have there a full harness that we built providing an agent with all the needed study materials, getting the agent to distill all the info into research and study notes and then autoreasearch on the skill untill it improved -- we picked previous problems that we already solved and got the agent to run with the skill trying to solve the same problme then we used llm as a judge with predefined deterministic rubrics to judge the output of the agent and use the result as input for another feedback loop

We kept looping and improving till we reached the result

In an earlier skill workspace for a localization-QA team, we built a product documentation workflow skill in a very similar fashion -- we got the gold standard from the human-authored docs the previous product owners had already built -- then we built our skill and kept running it on existing documentation tasks that we already solved before and have the gold standard for and compare. This way we were able to autoresearch untill the skill delivered the same output as the humans

At a games studio we also did a similar harness, I guided an engineer to build it and he did a structured-document generation skill using the same philosophy but slighly diff tool, i believe he used @docs/resources/pi-autoresearch to do the autoresearch loop -- the concept was the same. We asked the studio to give us their input documents and their output documents created by humans -- we then got the agent to create the skill and keep autoresearch looping untill the skill generated the same output as the humans


We also have something very similar done with a localization-QA team working with a game-content team -- where they used to write game scenarios manually themselves. We got the golden standards of what they used before, and then we got the agent to build a pipeline and autoresearch on the prompts until the agent would output the same quality or better than the humans. You can see in the repo also the quality report and the benchmarking.

We also built a task-decomposition workflow -- a powerful agentic system with full creation, validation, and looping to split tasks into small units of work that agents can then work on and have them validated. This allowed us to do complex tasks with models as small as haiku. Again the philosophy is the same.

In a lof of the repos I provided, I stored my transcripts and plans with the AI agents and docs so you can learn from those not just code

We @.agents/skills/premortem/SKILL.md as well.

The philosophy is simple and engineering inspired.
We split the work into verifiable tasks, we keep iterating till we reach the goal. We verify every step of work we do. We do not trust one agent. We trust concensus. 
Hence We sometimes spawn multiple verifier subagents for example and have them working until they reach concensus.

At some point a beautiful addition was the devils advocate verifier subagent which basically keeps kinda saying no with reason .. but once the other agents are in concensus they can over rule.

We want to build here a pipeline for creating skills as we need.
Inspired by the learning resources I just provided to you

I usually use @.agents/skills/autoresearch/ skill but I also noticed another eng used @docs/resources/pi-autoresearch we can learn from both and figure out what is best for us

You need to Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer. If a question can be answered by exploring the codebase, explore the codebase instead.

Ask me anything you need and let's spar and discuss together first

Remember, Your first action is to study THOROUGHLY all the inputs I just provided to you and distill your thoughts into @docs/thoughts/README.md you can create multiple files like we did in the earlier skill workspace research notes.
Remember to study transcirpts and plans as well from that earlier skill workspace.

We can work together on refining my needs as well
