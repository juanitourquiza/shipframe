# QA fast path / Atajo de QA

## English

`small` is a reduction in QA/test depth, not a review exemption. QA records the size and a concise rationale in its result. A small task is isolated (normally one or two functions) and must not change a public API, authentication or secrets handling, a database migration, or CI. Any of those risk areas makes it ineligible for `small`; classify it at least `medium`, or `large` when scope warrants. Reclassify upward whenever investigation or review finds additional risk.

Every code change still receives an independent final review of the complete diff. The reviewer escalates when necessary; this fast path never grants auto-approval, merge, publication, or deployment.

## Español

`small` reduce la profundidad de QA/pruebas; no exime de revisión. QA registra el tamaño y una justificación breve en su resultado. Una tarea pequeña es aislada (normalmente una o dos funciones) y no debe cambiar una API pública, autenticación o manejo de secretos, una migración de base de datos ni CI. Cualquiera de esos riesgos la excluye de `small`: clasifícala como mínimo `medium`, o `large` si el alcance lo requiere. Sube la clasificación cuando la investigación o la revisión detecte más riesgo.

Todo cambio de código sigue recibiendo una revisión final independiente del diff completo. El revisor escala la tarea cuando corresponda; este atajo nunca concede aprobación automática, merge, publicación ni despliegue.

## Contract checker

Run `python3 scripts/check-contracts.py` to validate skill and agent metadata. Regression cases: `python3 tests/test-contracts.py`. CI runs the checker on each push and pull request.
