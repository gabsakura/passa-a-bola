# Configuração do Google Maps

O Passa a Bola carrega a chave do Google Maps pelo ambiente local. Não coloque credenciais diretamente em arquivos Dart, XML, Swift ou HTML.

## 1. Preparar a chave

1. No [Google Cloud Console](https://console.cloud.google.com/), selecione ou crie um projeto.
2. Ative apenas as APIs utilizadas, como Maps JavaScript API, Maps SDK for Android, Maps SDK for iOS e Geocoding API.
3. Crie uma credencial e aplique restrições de aplicativo e de API.
4. Para uma publicação real, prefira chaves separadas e restritas para web, Android e iOS.

## 2. Configurar o ambiente local

Na raiz do projeto:

```powershell
Copy-Item .env.example .env
```

Preencha no arquivo `.env`:

```env
GOOGLE_MAPS_API_KEY=sua_chave_restrita
```

Em seguida, execute:

```powershell
.\scripts\prepare_env.ps1
```

O script gera arquivos locais ignorados pelo Git:

- `env.json`, usado pelo código Dart;
- `web/index.html`, usado no Flutter Web;
- `android/maps.properties`, usado pelo Android;
- `ios/Flutter/Secrets.xcconfig`, usado pelo iOS.

Para preparar o ambiente e iniciar o app de uma vez:

```powershell
.\scripts\run_local.ps1 -Device chrome
```

## 3. Verificação

- confirme que o mapa abre sem erros;
- teste a permissão de localização em um dispositivo real;
- teste busca de endereço e campeonatos próximos;
- confirme no console da nuvem que a chave está restrita aos aplicativos e APIs esperados;
- antes de publicar, verifique que `.env`, `env.json`, `maps.properties` e `Secrets.xcconfig` não aparecem no `git status`.

## Solução de problemas

Se o mapa não carregar, revise as APIs ativadas, as restrições da chave, o identificador do aplicativo e execute novamente `scripts/prepare_env.ps1`. Consulte também a [documentação oficial do Google Maps Platform](https://developers.google.com/maps/documentation).
