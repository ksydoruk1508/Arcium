# 💻💻💻 Arcium — Node Installation Guide

🟣 **Activity Type:** Node  
🟣 **Funding:** $14.00M  
🟣 **Investors:** [Coinbase Ventures, Anatoly Yakovenko, and others](https://cryptorank.io/ru/ico/elusiv)  
🟣 **Setup Time:** ~20 min  
🟣 **Minimum Requirements:** amd64 12 CPU / 32 RAM / 20GB SSD

---

## 🧠 About the Project

**Arcium** is a next-generation encrypted supercomputer designed for secure and scalable computations on encrypted data.  
It’s powered by **MPC (Multi-Party Computation)** technology, which ensures full confidentiality without revealing the original data.  

Arcium builds the foundation for **privacy-preserving infrastructure** across Web2 and Web3 — connecting developers, enterprises, and industries into one decentralized network where data remains protected at every step.

---

## 🚀 Public Testnet Phase 2

📅 **October 3, 2025** — Arcium launched **Public Testnet Phase 2**, the final stage before Mainnet Alpha.  
> ⚠️ Running a node is **voluntary**, and **not tied** to any airdrop or reward program.

---

## ⚙️ Node Installation

### ➡️ Step-by-Step Guide

**1️⃣ Download and run the setup script:**
```bash
wget -q -O arcium-node-hub.sh https://raw.githubusercontent.com/ksydoruk1508/Arcium/main/arcium-node-hub.sh && sudo chmod +x arcium-node-hub.sh && ./arcium-node-hub.sh
```

**2️⃣ Prepare the server:**  
Select:  
`1) Server Preparation (Docker, Rust, Solana, Node/Yarn, Anchor, arcup)`  
Wait until the setup is complete.

**3️⃣ Install and launch the node:**  
Select:  
`2) Node Installation and Launch`  
- When prompted for Solana Devnet RPC → just press **Enter** if you don’t have one.  
- When prompted for Solana Devnet WSS → press **Enter** again.  
  > Recommended RPC providers: [Helius](https://helius.xyz/) or [QuickNode](https://quicknode.com/)  
- Enter your **Node OFFSET** — any 8–10 digit combination.  
- When asked for IP → press **Enter**.

**4️⃣ Wallets and faucet:**  
The script will generate your wallets and suggest claiming tokens from a faucet.  
If the faucet fails, use: [https://faucet.solana.com/](https://faucet.solana.com/)  
Once you have a balance, the setup will continue automatically.

**5️⃣ Check node logs:**  
Go to:  
`5) Tools (logs, status, keys)` → View Logs  
✅ Logs should look similar to [this example](https://i.postimg.cc/Gmkry4M5/2025-10-11-162018.png)

**6️⃣ Verify node activity:**  
`5) Tools (logs, status, keys)` → `3) Check Node Activity`  
Should return **True**.

**7️⃣ Backup your keys:**  
`5) Tools (logs, status, keys)` → `9) Show Seed Phrases`  
Save the following files:
```
/root/arcium-node-setup/node-keypair.json  
/root/arcium-node-setup/callback-kp.json  
/root/arcium-node-setup/identity.pem
```

**8️⃣ Join a cluster:**  
If you want to join my cluster, send me your **NODE OFFSET**, visible under  
`5) Tools (logs, status, keys)` → `3) Check Node Activity`  
Then run the following command after I send you an invite:

```bash
arcium join-cluster true   --keypair-path /root/arcium-node-setup/node-keypair.json   --node-offset <YOUR_NODE_OFFSET>   --cluster-offset 10102025   --rpc-url https://api.devnet.solana.com/
```

Check status:  
`5) Tools (logs, status, keys)` → `2) Node Status`

---

## 🟠 Additional Resources

📘 **Official Docs:** [docs.arcium.com/developers/node-setup#devnet-rpc-provider-recommendations](https://docs.arcium.com/developers/node-setup#devnet-rpc-provider-recommendations)  
🌐 **Website:** [arcium.com](https://www.arcium.com/)  
💬 **X (Twitter):** [x.com/arciumhq](https://x.com/arciumhq)  
👾 **Discord:** [discord.gg/arcium](https://discord.com/invite/arcium)

---

✍️ Despite the team stating that running a node is voluntary and not rewarded, I decided to run at least one node — the project looks **promising** with **strong backing**.

---

📢 **Community Resources:**  
💬 Chat — [t.me/nod3r_team](https://t.me/nod3r_team)  
🤖 Bot — [t.me/wiki_nod3r_bot](https://t.me/wiki_nod3r_bot)

---

# 💻💻💻 Arcium — установка ноды

🟣 **Тип активности:** Ноды  
🟣 **Инвестиции:** $14.00M  
🟣 **Инвесторы:** [Coinbase Ventures, Anatoly Yakovenko и др.](https://cryptorank.io/ru/ico/elusiv)  
🟣 **Время выполнения:** ~20 мин  
🟣 **Системные требования:** amd64 12 CPU / 32 RAM / 20GB  SSD (минимальные)

---

## 🧠 О проекте

**Arcium** — это зашифрованный суперкомпьютер нового поколения, созданный для безопасных и масштабируемых вычислений над зашифрованными данными. В основе — технология **MPC (Multi-Party Computation)**, обеспечивающая конфиденциальность без раскрытия исходных данных.  
Arcium формирует инфраструктуру приватных вычислений для Web2 и Web3, объединяя разработчиков, компании и индустрии в единую децентрализованную сеть, где данные остаются защищёнными на каждом этапе.

---

## 🚀 Public Testnet Phase 2

📅 **03.10.2025** Arcium запустил **Public Testnet Phase 2**.  
🚨 Участие в тестнете — **добровольное**, без привязки к airdrop или наградам.  

---

## ⚙️ Установка ноды

➡️ **Шаг за шагом:**

1️⃣ **Загружаем скрипт:**
```bash
wget -q -O arcium-node-hub.sh https://raw.githubusercontent.com/ksydoruk1508/Arcium/main/arcium-node-hub.sh && sudo chmod +x arcium-node-hub.sh && ./arcium-node-hub.sh
```

2️⃣ **Подготовка сервера:**  
Выбираем пункт `1) Подготовка сервера (Docker, Rust, Solana, Node/Yarn, Anchor, arcup)` и дожидаемся завершения.

3️⃣ **Установка ноды:**  
Выбираем `2) Установка и запуск ноды`.  
- При запросе RPC Solana Devnet → просто жмём **Enter**, если нет своего.  
- При запросе RPC Solana Devnet WSS → тоже **Enter**, если нет своего.  
  > Рекомендуемые RPC: [Helius](https://helius.xyz/) или [QuickNode](https://quicknode.com/)  
- Введите **Node OFFSET** — придумайте комбинацию из 8–10 цифр.  
- При запросе IP → просто **Enter**.

4️⃣ **Кошельки и токены:**  
Скрипт создаст кошельки и предложит запросить токены с крана.  
Если кран не сработал — используем [https://faucet.solana.com/](https://faucet.solana.com/).  
После проверки баланса установка продолжится автоматически.

5️⃣ **Проверяем работу ноды:**  
`5) Инструменты (логи, статус, ключи)` → **Просмотр логов**  
✅ Должны быть логи как [в примере](https://i.postimg.cc/Gmkry4M5/2025-10-11-162018.png)

6️⃣ **Проверяем активность ноды:**  
`5) Инструменты (логи, статус, ключи)` → `3) Проверить активность ноды`  
Значение должно быть **True**.

7️⃣ **Делаем бэкапы:**  
`5) Инструменты (логи, статус, ключи)` → `9) Показать сид-фразы`  
Сохраняем файлы:
```
/root/arcium-node-setup/node-keypair.json  
/root/arcium-node-setup/callback-kp.json  
/root/arcium-node-setup/identity.pem
```

8️⃣ **Присоединение к кластеру:**  
Если хотите вступить в мой кластер, пришлите свой **NODE OFFSET**, узнайте его через:  
`5) Инструменты (логи, статус, ключи)` → `3) Проверить активность ноды`  
После приглашения выполняем:

```bash
arcium join-cluster true   --keypair-path /root/arcium-node-setup/node-keypair.json   --node-offset <ТВОЙ_NODE_OFFSET>   --cluster-offset 10102025   --rpc-url https://api.devnet.solana.com/
```

Проверяем статус:  
`5) Инструменты (логи, статус, ключи)` → `2) Статус ноды`

---

## 🟠 Дополнительно

📘 **Официальная инструкция:** [docs.arcium.com/developers/node-setup#devnet-rpc-provider-recommendations](https://docs.arcium.com/developers/node-setup#devnet-rpc-provider-recommendations)  
🌐 **Сайт:** [arcium.com](https://www.arcium.com/)  
💬 **X (Twitter):** [x.com/arciumhq](https://x.com/arciumhq)  
👾 **Discord:** [discord.gg/arcium](https://discord.com/invite/arcium)

---

✍️ Несмотря на заявление команды об отсутствии вознаграждений, я решил поднять хотя бы одну ноду — проект выглядит **перспективно** и имеет **сильных инвесторов**.

---

📢 **Полезные ресурсы сообщества:**  
💬 Чат — [t.me/nod3r_team](https://t.me/nod3r_team)  
🤖 Бот — [t.me/wiki_nod3r_bot](https://t.me/wiki_nod3r_bot)
