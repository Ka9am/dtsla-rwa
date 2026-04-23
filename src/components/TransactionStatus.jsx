import { TX_STATUS } from "../utils/constants";

const ETHERSCAN = "https://sepolia.etherscan.io";

function TransactionStatus({ status, txHash, error }) {
  if (status === TX_STATUS.IDLE) return null;

  const configs = {
    signing: {
      bg: "rgba(59,130,246,0.1)",
      color: "var(--color-primary)",
      border: "rgba(59,130,246,0.2)",
      text: "Confirm the transaction in MetaMask...",
    },
    pending: {
      bg: "rgba(245,158,11,0.1)",
      color: "var(--color-warning)",
      border: "rgba(245,158,11,0.2)",
      text: "Transaction submitted, waiting for confirmation...",
    },
    confirmed: {
      bg: "rgba(34,197,94,0.1)",
      color: "var(--color-success)",
      border: "rgba(34,197,94,0.2)",
      text: "Transaction confirmed! Tokens credited.",
    },
    failed: {
      bg: "rgba(239,68,68,0.1)",
      color: "var(--color-error)",
      border: "rgba(239,68,68,0.2)",
      text: error || "Transaction failed",
    },
  };

  const cfg = configs[status];
  if (!cfg) return null;

  const txUrl = ETHERSCAN + "/tx/" + txHash;

  const borderStyle = "1px solid " + cfg.border;

  const wrapperStyle = {
    padding: "12px 16px",
    borderRadius: "var(--radius-md)",
    fontSize: "14px",
    marginTop: "12px",
    background: cfg.bg,
    color: cfg.color,
    border: borderStyle,
  };

  const linkStyle = {
    color: "inherit",
    textDecoration: "underline",
    fontSize: "12px",
  };

  const showLink = txHash && status === TX_STATUS.PENDING;

  return (
    <div style={wrapperStyle}>
      <div>{cfg.text}</div>
      {showLink && (
        <a href={txUrl} target="_blank" rel="noopener noreferrer" style={linkStyle}>
          View on Etherscan
        </a>
      )}
    </div>
  );
}

export default TransactionStatus;
