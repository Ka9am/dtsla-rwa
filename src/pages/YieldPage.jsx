import { useWallet } from "../hooks/useWallet";
import { useYield } from "../hooks/useYield";
import TransactionStatus from "../components/TransactionStatus";
import { weiToEth } from "../utils/formatters";
import { TX_STATUS } from "../utils/constants";

function YieldPage() {
  const { isConnected, connect } = useWallet();
  const { pendingYield, loading, txStatus, txHash, error, claimYield } = useYield();

  if (!isConnected) {
    return (
      <div style={{ padding: "48px 0" }}>
        <h1 style={{ marginBottom: "16px" }}>My Yield</h1>
        <p style={{ color: "var(--color-text-secondary)", marginBottom: "24px" }}>
          Connect your wallet to see your yield.
        </p>
        <button
          onClick={connect}
          style={{
            padding: "12px 24px",
            borderRadius: "var(--radius-sm)",
            border: "none",
            background: "var(--color-primary)",
            color: "white",
            fontSize: "16px",
          }}>
          Connect Wallet
        </button>
      </div>
    );
  }

  const isPending = txStatus === TX_STATUS.SIGNING || txStatus === TX_STATUS.PENDING;
  const yieldAmount = pendingYield ? weiToEth(pendingYield) : "0";
  const hasYield = pendingYield && pendingYield > 0n;

  return (
    <div style={{ padding: "48px 0", maxWidth: "500px" }}>
      <h1 style={{ marginBottom: "32px" }}>My Yield</h1>

      <div style={{
        background: "var(--color-surface)",
        border: "1px solid var(--color-border)",
        borderRadius: "var(--radius-lg)",
        padding: "32px",
      }}>
        <p style={{ color: "var(--color-text-muted)", fontSize: "14px", marginBottom: "8px" }}>
          Pending yield
        </p>

        {loading ? (
          <p style={{ color: "var(--color-text-secondary)" }}>Loading...</p>
        ) : (
          <p style={{ fontSize: "36px", fontWeight: 600, marginBottom: "24px" }}>
            {yieldAmount} ETH
          </p>
        )}

        <button
          onClick={claimYield}
          disabled={isPending || !hasYield}
          style={{
            width: "100%",
            padding: "12px",
            borderRadius: "var(--radius-sm)",
            border: "none",
            background: hasYield ? "var(--color-primary)" : "var(--color-border)",
            color: hasYield ? "white" : "var(--color-text-muted)",
            fontSize: "16px",
            opacity: isPending ? 0.7 : 1,
          }}>
          {isPending ? "Processing..." : "Claim Yield"}
        </button>

        <TransactionStatus status={txStatus} txHash={txHash} error={error} />
      </div>

      <p style={{ color: "var(--color-text-muted)", fontSize: "13px", marginTop: "16px" }}>
        Yield is distributed by the property owner and split proportionally
        based on how many tokens you hold.
      </p>
    </div>
  );
}

export default YieldPage;