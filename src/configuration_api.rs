// Built-in uses
use std::sync::{Arc, RwLock};

// External uses
use jsonrpc_core::Result;
use jsonrpc_derive::rpc;
use zksync_core::api_server::web3::backend_jsonrpc::error::into_jsrpc_error;
use zksync_web3_decl::error::Web3Error;

// Workspace uses

// Local uses
use crate::{
    node::InMemoryNodeInner,
    node::ShowCalls,
    node::ShowVMDetails,
    node::{ShowGasDetails, ShowStorageLogs},
    observability::LogLevel,
};

pub struct ConfigurationApiNamespace<S> {
    node: Arc<RwLock<InMemoryNodeInner<S>>>,
}

impl<S> ConfigurationApiNamespace<S> {
    pub fn new(node: Arc<RwLock<InMemoryNodeInner<S>>>) -> Self {
        Self { node }
    }
}

#[rpc]
pub trait ConfigurationApiNamespaceT {
    /// Get the InMemoryNodeInner's show_calls property as a string
    ///
    /// # Returns
    /// The current `show_calls` value for the InMemoryNodeInner.
    #[rpc(name = "config_getShowCalls", returns = "String")]
    fn config_get_show_calls(&self) -> Result<String>;

    /// Get the InMemoryNodeInner's current_timestamp property
    ///
    /// # Returns
    /// The current `current_timestamp` value for the InMemoryNodeInner.
    #[rpc(name = "config_getCurrentTimestamp", returns = "u64")]
    fn config_get_current_timestamp(&self) -> Result<u64>;

    /// Set show_calls for the InMemoryNodeInner
    ///
    /// # Parameters
    /// - `value`: A ShowCalls enum to update show_calls to
    ///
    /// # Returns
    /// The updated/current `show_calls` value for the InMemoryNodeInner.
    #[rpc(name = "config_setShowCalls", returns = "String")]
    fn config_set_show_calls(&self, value: String) -> Result<String>;

    /// Set show_storage_logs for the InMemoryNodeInner
    ///
    /// # Parameters
    /// - `value`: A ShowStorageLogs enum to update show_storage_logs to
    ///
    /// # Returns
    /// The updated/current `show_storage_logs` value for the InMemoryNodeInner.
    #[rpc(name = "config_setShowStorageLogs", returns = "String")]
    fn config_set_show_storage_logs(&self, value: String) -> Result<String>;

    /// Set show_vm_details for the InMemoryNodeInner
    ///
    /// # Parameters
    /// - `value`: A ShowVMDetails enum to update show_vm_details to
    ///
    /// # Returns
    /// The updated/current `show_vm_details` value for the InMemoryNodeInner.
    #[rpc(name = "config_setShowVmDetails", returns = "String")]
    fn config_set_show_vm_details(&self, value: String) -> Result<String>;

    /// Set show_gas_details for the InMemoryNodeInner
    ///
    /// # Parameters
    /// - `value`: A ShowGasDetails enum to update show_gas_details to
    ///
    /// # Returns
    /// The updated/current `show_gas_details` value for the InMemoryNodeInner.
    #[rpc(name = "config_setShowGasDetails", returns = "String")]
    fn config_set_show_gas_details(&self, value: String) -> Result<String>;

    /// Set resolve_hashes for the InMemoryNodeInner
    ///
    /// # Parameters
    /// - `value`: A bool to update resolve_hashes to
    ///
    /// # Returns
    /// The updated `resolve_hashes` value for the InMemoryNodeInner.
    #[rpc(name = "config_setResolveHashes", returns = "bool")]
    fn config_set_resolve_hashes(&self, value: bool) -> Result<bool>;

    /// Set the logging for the InMemoryNodeInner
    ///
    /// # Parameters
    /// - `level`: The log level to set. One of: ["trace", "debug", "info", "warn", "error"]
    ///
    /// # Returns
    /// `true` if the operation succeeded, `false` otherwise.
    #[rpc(name = "config_setLogLevel", returns = "bool")]
    fn config_set_log_level(&self, level: LogLevel) -> Result<bool>;

    /// Set the logging for the InMemoryNodeInner
    ///
    /// # Parameters
    /// - `level`: The logging directive to set. Example:
    ///     * "my_crate=debug"
    ///     * "my_crate::module=trace"
    ///     * "my_crate=debug,other_crate=warn"
    ///
    /// # Returns
    /// `true` if the operation succeeded, `false` otherwise.
    #[rpc(name = "config_setLogging", returns = "bool")]
    fn config_set_logging(&self, directive: String) -> Result<bool>;
}

impl<S: std::marker::Send + std::marker::Sync + 'static> ConfigurationApiNamespaceT
    for ConfigurationApiNamespace<S>
{
    fn config_get_show_calls(&self) -> Result<String> {
        let reader = self.node.read().unwrap();
        Ok(reader.show_calls.to_string())
    }

    fn config_get_current_timestamp(&self) -> Result<u64> {
        let reader = self.node.read().unwrap();
        Ok(reader.current_timestamp)
    }

    fn config_set_show_calls(&self, value: String) -> Result<String> {
        let show_calls = match value.parse::<ShowCalls>() {
            Ok(value) => value,
            Err(_) => {
                let reader = self.node.read().unwrap();
                return Ok(reader.show_calls.to_string());
            }
        };

        let mut inner = self.node.write().unwrap();
        inner.show_calls = show_calls;
        Ok(inner.show_calls.to_string())
    }

    fn config_set_show_storage_logs(&self, value: String) -> Result<String> {
        let show_storage_logs = match value.parse::<ShowStorageLogs>() {
            Ok(value) => value,
            Err(_) => {
                let reader = self.node.read().unwrap();
                return Ok(reader.show_storage_logs.to_string());
            }
        };

        let mut inner = self.node.write().unwrap();
        inner.show_storage_logs = show_storage_logs;
        Ok(inner.show_storage_logs.to_string())
    }

    fn config_set_show_vm_details(&self, value: String) -> Result<String> {
        let show_vm_details = match value.parse::<ShowVMDetails>() {
            Ok(value) => value,
            Err(_) => {
                let reader = self.node.read().unwrap();
                return Ok(reader.show_vm_details.to_string());
            }
        };

        let mut inner = self.node.write().unwrap();
        inner.show_vm_details = show_vm_details;
        Ok(inner.show_vm_details.to_string())
    }

    fn config_set_show_gas_details(&self, value: String) -> Result<String> {
        let show_gas_details = match value.parse::<ShowGasDetails>() {
            Ok(value) => value,
            Err(_) => {
                let reader = self.node.read().unwrap();
                return Ok(reader.show_gas_details.to_string());
            }
        };

        let mut inner = self.node.write().unwrap();
        inner.show_gas_details = show_gas_details;
        Ok(inner.show_gas_details.to_string())
    }

    fn config_set_resolve_hashes(&self, value: bool) -> Result<bool> {
        let mut inner = self.node.write().unwrap();
        inner.resolve_hashes = value;
        Ok(inner.resolve_hashes)
    }

    fn config_set_log_level(&self, level: LogLevel) -> Result<bool> {
        if let Some(observability) = &self
            .node
            .read()
            .map_err(|_| into_jsrpc_error(Web3Error::InternalError))?
            .observability
        {
            match observability.set_log_level(level.clone()) {
                Ok(_) => tracing::info!("set log level to '{}'", level),
                Err(err) => {
                    tracing::error!("failed setting log level {:?}", err);
                    return Ok(false);
                }
            }
        }
        Ok(true)
    }

    fn config_set_logging(&self, directive: String) -> Result<bool> {
        if let Some(observability) = &self
            .node
            .read()
            .map_err(|_| into_jsrpc_error(Web3Error::InternalError))?
            .observability
        {
            match observability.set_logging(&directive) {
                Ok(_) => tracing::info!("set logging to '{}'", directive),
                Err(err) => {
                    tracing::error!("failed setting logging to '{}': {:?}", directive, err);
                    return Ok(false);
                }
            }
        }
        Ok(true)
    }
}
