# karenluau — батут с прокачкой силы прыжка

Батут для Roblox: каждый прыжок на нём даёт **+1 к силе прыжка**, а сила
увеличивает и высоту подброса батутом, и обычный прыжок персонажа.
Сверху экрана показывается анимированный HUD с текущей силой.

## Установка

### Вариант 1. Вручную в Roblox Studio

| Файл | Куда | Тип объекта | Имя |
|---|---|---|---|
| `src/shared/TrampolineConfig.lua` | ReplicatedStorage | ModuleScript | `TrampolineConfig` |
| `src/server/TrampolineServer.server.lua` | ServerScriptService | Script | `TrampolineServer` |
| `src/client/TrampolineBounce.client.lua` | StarterPlayer → StarterPlayerScripts | LocalScript | `TrampolineBounce` |
| `src/client/JumpPowerHUD.client.lua` | StarterPlayer → StarterPlayerScripts | LocalScript | `JumpPowerHUD` |

Имя ModuleScript должно быть именно `TrampolineConfig`.

### Вариант 2. Rojo

```
rojo serve
```

и подключиться плагином Rojo в Studio (`default.project.json` уже настроен).

## Как это работает

- При старте сервер сам строит батут в точке `TrampolinePosition`, если в игре ещё
  нет батутов. Свой батут можно сделать из любого Part: добавьте ему тег
  `TrampolinePad` (Properties → Tags), и автоматический батут не появится.
- Клиент подбрасывает персонажа сразу при касании (без задержки), сервер проверяет
  прыжок (кулдаун, расстояние до батута) и начисляет силу в `leaderstats`.
- Сила сохраняется в DataStore. Чтобы сохранение работало в Studio, включите
  Game Settings → Security → **Enable Studio Access to API Services**.

Все числа (сила за прыжок, высота подброса, лимиты, размер и цвета батута)
настраиваются в `TrampolineConfig`.
