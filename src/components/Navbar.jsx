import { Link } from "react-router-dom";
import { useWallet } from "../hooks/useWallet";
import { formatAddress } from "../utils/formatters";

function Navbar() {
  const { address, isConnected, isConnecting, connect, disconnect } = useWallet();

  return (
    <nav style={{
      borderBottom: "1px solid var(--color-border)",
      padding: "16px 24px",
      display: "flex",
      justifyContent: "space-between",
      alignItems: "center",
      maxWidth: "1200px",
      margin: "0 auto",
    }}>
      <div style={{ display: "flex", gap: "32px", alignItems: "center" }}>
        <Link to="/" style={{ color: "var(--color-text-primary)", fontWeight: 600, fontSize: "18px" }}>
          RWA Estate
        </Link>
        <Link to="/properties" style={{ color: "var(--color-text-secondary)" }}>Properties</Link>
        <Link to="/portfolio" style={{ color: "var(--color-text-secondary)" }}>Portfolio</Link>
        <Link to="/yield" style={{ color: "var(--color-text-secondary)" }}>Yield</Link>
      </div>

      <div>
        {isConnected ? (
          <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
            <span style={{ color: "var(--color-text-secondary)", fontSize: "14px" }}>
              {formatAddress(address)}
            </span>
            <button
              onClick={disconnect}
              style={{
                padding: "8px 16px",
                borderRadius: "var(--radius-sm)",
                border: "1px solid var(--color-border)",
                background: "transparent",
                color: "var(--color-text-primary)",
                fontSize: "14px",
              }}>
              Disconnect
            </button>
          </div>
        ) : (
          <button
            onClick={connect}
            disabled={isConnecting}
            style={{
              padding: "8px 16px",
              borderRadius: "var(--radius-sm)",
              border: "none",
              background: "var(--color-primary)",
              color: "white",
              fontSize: "14px",
              opacity: isConnecting ? 0.7 : 1,
            }}>
            {isConnecting ? "Connecting..." : "Connect Wallet"}
          </button>
        )}
      </div>
    </nav>
  );
}

export default Navbar;