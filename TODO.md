- refactor les charts pour éviter de transformer les IDs de devices en atom. Probablement pas
  besoin de tracker les data dans des assigns séparés maintenant que le charts sont rendus à part
- protéger l'interface web avec un mot de passe
- extraire client signalr
- gérer les messages avec type "complete"
- gérer les messages avec target "GatewayValuesReceived"
- setuper telemetry
  - utiliser la telemetry pour tracker les erreurs de restart du client websocket au lieu du wrapper manuel
