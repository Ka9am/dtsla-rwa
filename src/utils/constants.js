// Статусы транзакций — используем везде одинаково
export const TX_STATUS = {
  IDLE: "idle",           // ничего не происходит
  SIGNING: "signing",     // ждём подписи в MetaMask
  PENDING: "pending",     // транзакция отправлена, ждём подтверждения
  CONFIRMED: "confirmed", // транзакция подтверждена
  FAILED: "failed",       // транзакция упала
};

// Ссылка на Etherscan для Sepolia
export const ETHERSCAN_BASE_URL = "https://sepolia.etherscan.io";