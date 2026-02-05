import os

class BackendConfig:
    """
    D56.01.8: Centralized Backend Configuration.
    Ensures deterministic behavior across Local (Lab) and Cloud Run (Prod).
    """
    
    # 1. Server Binding (Cloud Run Compliance)
    # MUST bind to 0.0.0.0 and adhere to $PORT injection
    HOST = "0.0.0.0"
    PORT = int(os.getenv("PORT", "8000"))
    
    # 2. Identity & Mode
    # SYSTEM_MODE: LAB (Local) vs PROD (Cloud)
    # Default to PROD to be safe (Fail Secure)
    SYSTEM_MODE = os.getenv("SYSTEM_MODE", "PROD")
    
    # FOUNDER_BUILD: 1 = Enabled (Bypasses some checks, enables Lab routes)
    FOUNDER_BUILD = os.getenv("FOUNDER_BUILD", "0") == "1"
    
    # 3. Auth Secrets
    # FOUNDER_KEY: The shared secret for "X-Founder-Key"
    FOUNDER_KEY = os.getenv("FOUNDER_KEY", "")
    
    # 4. Observability
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
    
    @classmethod
    def is_prod(cls) -> bool:
        return cls.SYSTEM_MODE == "PROD"
        
    @classmethod
    def get_startup_summary(cls):
        """
        Returns safe startup summary for logs. NO SECRETS.
        """
        return {
            "mode": cls.SYSTEM_MODE,
            "port": cls.PORT,
            "founder_build": cls.FOUNDER_BUILD,
            "key_configured": bool(cls.FOUNDER_KEY),
        }
