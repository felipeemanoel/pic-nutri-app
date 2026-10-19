# Notificações no app

Regras completas (servidor, painel, estados e configuração de produção): `pic-nutri/docs/notificacoes.md`.

## O que fica onde

| Recurso | Implementação |
| --- | --- |
| Central de notificações (`/notifications`, sino no Início) | `features/notifications/` — histórico paginado vindo da API, lidas/não lidas, marcar uma ou todas. Funciona sem permissão de push. |
| Configurações (`/profile/notifications`) | Chave geral do aparelho, situação da permissão do sistema (com atalho para as configurações do aparelho), categorias, lembretes por categoria e período de silêncio. |
| Lembretes pessoais | Notificações **locais** (`flutter_local_notifications`), agendadas por `ReminderScheduler` a partir de `GET /reminders` + preferências. |
| Mensagens do servidor | Push FCM (`core/notifications/push_messaging.dart`); também gravadas na central. |

## Lembretes locais (`ReminderScheduler`)

- Reagenda ao entrar no app, ao voltar ao app (`resumed`), ao mudar preferências ou lembretes e após registrar água ou refeição.
- Lembretes de todos os dias viram um aviso diário por horário; os demais, um por dia da semana. A repetição no dia (`interval_minutes` até `end_time`) gera um horário para cada intervalo.
- Os avisos condicionais (`water_goal`, `daily_log`, `daily_goals`) são datados para os próximos 7 dias, e o de hoje sai da lista se a meta já foi cumprida.
- Não agenda categorias desligadas nem horários dentro do período de silêncio.
- Limite de 60 agendamentos (o iOS aceita até 64): ficam os mais próximos.
- Ao desativar as notificações do aparelho, ou ao sair da conta, tudo é cancelado.

## Push do servidor

- Token registrado após o login com notificações ativas. Token renovado pelo Firebase é enviado com `previous_token`, e o servidor troca o antigo. Ao sair da conta ou desativar, o token é removido. Se ele foi registrado em outra abertura do app, é lido de novo do Firebase antes de remover.
- Com o app aberto, o Android mostra o aviso pelo canal `server`, com id fixo por mensagem (novas tentativas não duplicam); o iOS mostra pelo sistema. Em ambos os casos, a central e o contador são atualizados.
- Ao tocar no aviso, o app avisa a API (`/notifications/{id}/opened`) e abre a tela. Só telas de uma lista fechada são abertas (`NotificationRoutes`); qualquer outra rota abre a central.

## Privacidade

- **Android:** visibilidade privada nos dois canais (`reminders` e `server`), então o conteúdo fica oculto na tela bloqueada.
- **Medicamento:** o lembrete usa título e texto neutros ("Lembrete do PicNutri").
- **Lembretes personalizados:** o formulário avisa para não colocar dados de saúde no título.

## Permissão

- A permissão é pedida só depois de uma explicação, ao ligar as notificações nas configurações.
- A situação real vem do canal nativo `br.com.picnutri/notification_settings`:
  - `status`: `granted`, `denied` ou `notDetermined`;
  - `open`: abre as configurações de notificação do app no sistema.
- O canal está implementado em `MainActivity.kt` e `AppDelegate.swift`.
- Permissão negada: o app mostra a situação e oferece "Abrir configurações". A situação é reavaliada ao voltar ao app.
