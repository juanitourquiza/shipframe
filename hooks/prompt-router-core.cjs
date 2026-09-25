'use strict';

const ROUTE_ACTION = /\b(implement|build|create|add|change|modify|fix|debug|refactor|review|test|ship|deploy|release|migrate|integrate|upgrade|upgrading|curate|analyze|scan|respond|verify|implementar|implementa|construir|crear|agregar|agrega|cambiar|modificar|arreglar|arregla|corregir|corrige|depurar|depura|refactorizar|revisar|revisa|probar|prueba|desplegar|publicar|migrar|integrar|actualizar|actualiza|subir|organizar|organiza|analizar|analiza|escanear|responder|responde|verificar|verifica)\b/i;
const WORK_CONTEXT = /\b(repo(?:sitory)?|code(?:base)?|code|diff|project|feature|bug|regression|tests?|pull request|pr|release|deploy|mcp|api|workflow|specs?|retro|security|vulnerabilit(?:y|ies)|dependencies|dependency|e2e|end[- ]to[- ]end|browser|contract|incident|outage|memory|repositorio|c[oó]digo|proyecto|funcionalidad|error|regresi[oó]n|pruebas?|cambio|implementaci[oó]n|lanzamiento|despliegue|retrospectiva|seguridad|vulnerabilidades|dependencias|incidente|ca[ií]da|memoria|contrato|navegador)\b/i;
const EXPLICIT_SKILL = /(?:^|\s)(?:\$[\w:-]+|\/shipframe:[\w-]+)(?:\s|$)/i;
const GREETING = /^(?:hi|hello|hey|hola|buenos d[ií]as|buenas tardes|buenas noches|gracias|thanks|thank you)[!.\s]*$/i;
const SIMPLE_QUESTION = /^(?:what|who|when|where|why|how|qué|que|qui[eé]n|cu[aá]ndo|d[oó]nde|por qu[eé]|c[oó]mo)\b/i;

function classifyPrompt(value) {
  const prompt = typeof value === 'string' ? value.trim() : '';
  if (!prompt || GREETING.test(prompt) || EXPLICIT_SKILL.test(prompt)) {
    return { decision: 'bypass', reason: 'ordinary-or-explicit-skill' };
  }

  if (/\b(use|using|with|utili[cz](?:a|ando|ar|emos|e)|usa|usar|usando|con)\s+shipframe\b/i.test(prompt) || /\bshipframe\b/i.test(prompt) && /\b(please|por favor|workflow|flujo|proceso)\b/i.test(prompt)) {
    return { decision: 'route', reason: 'explicit-shipframe' };
  }

  const words = prompt.split(/\s+/).filter(Boolean).length;
  if (words <= 20 && SIMPLE_QUESTION.test(prompt) && !WORK_CONTEXT.test(prompt)) {
    return { decision: 'bypass', reason: 'simple-question' };
  }

  if (ROUTE_ACTION.test(prompt) && WORK_CONTEXT.test(prompt)) {
    return { decision: 'route', reason: 'clear-work-request' };
  }

  if (words > 35 || /\b(step[- ]by[- ]step|end[- ]to[- ]end|multi[- ]step|paso a paso|de principio a fin)\b/i.test(prompt)) {
    return { decision: 'suggest', reason: 'complex-but-unclear' };
  }

  if (/\b(help|review|look at|take a look|analyze|analyse|investigate|ayuda|ay[uú]dame|revisa|analiza|investiga)\b/i.test(prompt)) {
    return { decision: 'suggest', reason: 'workflow-may-help' };
  }

  if (WORK_CONTEXT.test(prompt) && /\b(new feature|feature request|i need|i want|could you|una idea|necesito|quiero|podr[ií]as)\b/i.test(prompt)) {
    return { decision: 'suggest', reason: 'potential-project-work' };
  }

  if (ROUTE_ACTION.test(prompt)) {
    return { decision: 'suggest', reason: 'work-request-needs-context' };
  }

  return { decision: 'bypass', reason: 'ordinary-request' };
}

function routingContext(result) {
  if (result.decision === 'route') {
    return 'ShipFrame fast path: this is substantive workflow work. Follow ShipFrame context and the matching intent workflow before acting. The user’s explicit instructions take precedence; this guidance is advisory.';
  }
  if (result.decision === 'suggest') {
    return 'ShipFrame fast path: this request may benefit from a matching ShipFrame workflow. Assess the scope; suggest or invoke the smallest relevant workflow only if useful. The user’s explicit instructions take precedence; this guidance is advisory.';
  }
  return '';
}

function latestUserMessage(messages) {
  if (!Array.isArray(messages)) return undefined;
  for (let index = messages.length - 1; index >= 0; index -= 1) {
    const message = messages[index];
    if (message?.info?.role !== 'user' && message?.role !== 'user') continue;
    const parts = message.parts ?? message.content ?? [];
    if (typeof parts === 'string') return { id: message.info?.id ?? message.id, text: parts };
    if (!Array.isArray(parts)) continue;
    return {
      id: message.info?.id ?? message.id,
      text: parts.map((part) => typeof part === 'string' ? part : (part?.text ?? '')).filter(Boolean).join('\n'),
    };
  }
  return undefined;
}

function latestUserText(messages) {
  return latestUserMessage(messages)?.text ?? '';
}

module.exports = { classifyPrompt, latestUserMessage, latestUserText, routingContext };
