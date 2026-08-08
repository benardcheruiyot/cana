import React from 'react';
import PropTypes from 'prop-types';

export default function StatusMessage({ loading, error, children }) {
  if (loading) {
    return <div className="status-message">Loading…</div>;
  }
  if (error) {
    return <div className="status-message error">{error.message || 'Something went wrong.'}</div>;
  }
  return <>{children}</>;
}

StatusMessage.propTypes = {
  loading: PropTypes.bool.isRequired,
  error: PropTypes.object,
  children: PropTypes.node.isRequired,
};
