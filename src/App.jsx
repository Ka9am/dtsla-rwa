import { BrowserRouter, Routes, Route } from "react-router-dom";
import Navbar from "./components/Navbar";
import HomePage from "./pages/HomePage";
import PropertiesPage from "./pages/PropertiesPage";
import PropertyDetailPage from "./pages/PropertyDetailPage";
import PortfolioPage from "./pages/PortfolioPage";
import YieldPage from "./pages/YieldPage";

function App() {
  return (
    <BrowserRouter>
      <Navbar />
      <main style={{ maxWidth: "1200px", margin: "0 auto", padding: "0 24px" }}>
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/properties" element={<PropertiesPage />} />
          <Route path="/properties/:id" element={<PropertyDetailPage />} />
          <Route path="/portfolio" element={<PortfolioPage />} />
          <Route path="/yield" element={<YieldPage />} />
        </Routes>
      </main>
    </BrowserRouter>
  );
}

export default App;