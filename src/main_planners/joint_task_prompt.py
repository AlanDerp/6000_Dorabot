from .prompt_builder import PromptBuilder


def build_joint_task_text(global_state):
    """Build the centralized pi05 language prompt from Dorabot global state."""

    active = []
    for agent in sorted(global_state.get("agents", []), key=lambda item: item["id"]):
        destination = agent.get("destination")
        if destination is None:
            active.append(f"agent {agent['id']} should stop")
            continue

        task = agent.get("task", {})
        task_type = task.get("type")
        has_item = "carrying item" if task.get("has_item") else "empty"
        port_kind = task.get("port_kind") or "unknown port"
        agent_state = agent.get("state") or "unknown state"
        last_event = task.get("last_event") or "no recent task event"
        active.append(
            "agent {} is {}, state {}, event {}, task {}, target {} {}, navigate to assigned waypoint ({:.2f}, {:.2f})".format(
                agent["id"],
                has_item,
                agent_state,
                last_event,
                task_type,
                port_kind,
                task.get("port_id"),
                destination["x"],
                destination["y"],
            )
        )

    rules = " ".join(
        PromptBuilder.DEFAULT_RULES
        + [
            "Loading and unloading ports are not final geometric goals; agents must follow assigned entry, queue, and operation waypoints.",
            "After loading, carry the item to its assigned unloading port. After unloading, request a new loading task.",
            "Resolve multi-agent deadlocks by assigning clear yield or escape motions to specific agents.",
        ]
    )
    return "Plan coordinated collision-free warehouse motion for all agents. {}. Rules: {}".format(
        "; ".join(active), rules
    )
