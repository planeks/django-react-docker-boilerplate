import { render, screen } from "@testing-library/react";
import { describe, it, expect, vi } from "vitest";
import App from "../App";

// Mock Sentry to avoid initialization side effects in tests
vi.mock("@sentry/react", () => ({
  // eslint-disable-next-line react/prop-types
  ErrorBoundary: ({ children }) => <>{children}</>,
}));

// Mock FontAwesome to avoid icon registration issues
vi.mock("@fortawesome/react-fontawesome", () => ({
  FontAwesomeIcon: () => <span data-testid="icon" />,
}));

describe("App", () => {
  it("renders without crashing", () => {
    render(<App />);
    expect(screen.getByText(/Hello Dev World/i)).toBeInTheDocument();
  });
});
