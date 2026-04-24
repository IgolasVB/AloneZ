# AloneZ

Um jogo de nave espacial estilo arcade desenvolvido em Flutter utilizando a engine Flame. Desvie, atire, colete corações para recuperar sua vida e sobreviva o máximo que puder!

## 🚀 Como Rodar o Jogo Localmente

Para rodar o projeto na sua máquina em modo de desenvolvimento:

1. Certifique-se de ter o [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.
2. Abra o terminal na pasta raiz do projeto (`alonez`).
3. Instale as dependências:
   ```bash
   flutter pub get
   ```
4. Inicie o emulador (ou conecte seu celular) e rode o comando:
   ```bash
   flutter run
   ```

## 📦 Como Gerar o APK (Android)

Para criar o arquivo instalável (APK) para celulares Android:

1. No terminal, na raiz do projeto, execute o comando de build:
   ```bash
   flutter build apk
   ```
2. Após o término do processo, o arquivo `.apk` gerado estará pronto no caminho:
   `build/app/outputs/flutter-apk/app-release.apk`
3. Basta transferir esse arquivo para o seu celular Android e realizar a instalação.

## 🐙 Como Subir Atualizações para o GitHub

Sempre que fizer modificações no código, siga estes passos para salvar e enviar para o repositório remoto:

1. Adicione todas as modificações:
   ```bash
   git add .
   ```
2. Crie o commit informando o que foi alterado:
   ```bash
   git commit -m "Descreva suas alterações aqui"
   ```
3. Envie as modificações para o GitHub:
   ```bash
   git push origin master
   ```
   *(Nota: Se sua branch principal se chamar `main`, use `git push origin main`)*

## 🏷️ Como Criar uma Tag de Versão e Subir

Tags são utilizadas para marcar versões específicas do jogo (ex: `v0.0.1`, `v1.0.0`).

1. Primeiro, atualize a versão do jogo no arquivo `pubspec.yaml` (ex: de `0.0.1+1` para `0.0.2+2`).
2. Adicione e faça o commit dessa alteração:
   ```bash
   git add pubspec.yaml
   git commit -m "Lançamento da versão v0.0.2"
   ```
3. Crie a tag localmente (com o mesmo nome da versão):
   ```bash
   git tag v0.0.2
   ```
4. Suba o novo código e a nova tag para o GitHub:
   ```bash
   git push origin master
   git push origin v0.0.2
   ```
   *(Dica: Se quiser enviar todas as tags que você criou de uma vez, pode rodar `git push --tags`)*
