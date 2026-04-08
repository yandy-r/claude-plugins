---
name: python-testing
description: Python testing patterns using pytest — TDD methodology, fixtures (function/module/session scopes), parametrization, markers, mocking with unittest.mock, async tests with pytest-asyncio, tmp_path, conftest.py organization, and coverage targets. Use when the user is writing Python tests, adding test coverage to Python code, asks about pytest, @pytest.fixture, @pytest.mark.parametrize, @patch / Mock / MagicMock / autospec, pytest-asyncio, conftest.py, tmp_path / tmpdir, pytest --cov, or wants TDD guidance for a Python project.
---

# Python Testing Patterns

Comprehensive testing strategies for Python applications using pytest, TDD methodology, and best practices.

## When to Activate

- Writing new Python code (follow TDD: red, green, refactor)
- Designing test suites for Python projects
- Reviewing Python test coverage
- Setting up testing infrastructure

## TDD Workflow for Python

### The RED-GREEN-REFACTOR Cycle

```text
RED      → Write a failing test for the desired behavior
GREEN    → Write minimal code to make the test pass
REFACTOR → Improve code while keeping tests green
REPEAT   → Continue with the next requirement
```

### Step-by-Step TDD in Python

```python
# Step 1: Write failing test (RED)
# test_calculator.py
def test_add_numbers():
    result = add(2, 3)
    assert result == 5

# Step 2: Run test - verify FAIL
# $ pytest
# NameError: name 'add' is not defined

# Step 3: Write minimal implementation (GREEN)
# calculator.py
def add(a: int, b: int) -> int:
    return a + b

# Step 4: Run test - verify PASS
# $ pytest
# 1 passed

# Step 5: Refactor if needed, verify tests still pass
```

### Coverage Targets

| Code Type | Target |
|-----------|--------|
| Critical business logic | 100% |
| Public APIs | 90%+ |
| General code | 80%+ |
| Generated/boilerplate | Exclude |

```bash
pytest --cov=mypackage --cov-report=term-missing --cov-report=html
```

## pytest Fundamentals

### Basic Test Structure

```python
import pytest

def test_addition():
    """Test basic addition."""
    assert 2 + 2 == 4

def test_string_uppercase():
    """Test string uppercasing."""
    text = "hello"
    assert text.upper() == "HELLO"

def test_list_append():
    """Test list append."""
    items = [1, 2, 3]
    items.append(4)
    assert 4 in items
    assert len(items) == 4
```

### Assertions

```python
# Equality
assert result == expected

# Inequality
assert result != unexpected

# Truthiness / identity
assert result          # truthy
assert not result      # falsy
assert result is True
assert result is None

# Membership
assert item in collection
assert item not in collection

# Comparisons
assert result > 0
assert 0 <= result <= 100

# Type checking
assert isinstance(result, str)

# Exception testing
with pytest.raises(ValueError):
    raise ValueError("error message")

# Match exception message (regex)
with pytest.raises(ValueError, match="invalid input"):
    raise ValueError("invalid input provided")

# Inspect exception attributes
with pytest.raises(ValueError) as exc_info:
    raise ValueError("error message")
assert str(exc_info.value) == "error message"
```

## Fixtures

### Basic Fixture Usage

```python
import pytest

@pytest.fixture
def sample_data():
    """Fixture providing sample data."""
    return {"name": "Alice", "age": 30}

def test_sample_data(sample_data):
    """Test using the fixture."""
    assert sample_data["name"] == "Alice"
    assert sample_data["age"] == 30
```

### Fixture with Setup/Teardown

```python
@pytest.fixture
def database():
    """Fixture with setup and teardown."""
    # Setup
    db = Database(":memory:")
    db.create_tables()
    db.insert_test_data()

    yield db  # Provide to test

    # Teardown
    db.close()

def test_database_query(database):
    """Test database operations."""
    result = database.query("SELECT * FROM users")
    assert len(result) > 0
```

### Fixture Scopes

```python
# Function scope (default) - runs for each test
@pytest.fixture
def temp_file(tmp_path):
    f = tmp_path / "temp.txt"
    f.write_text("hello")
    return f

# Module scope - runs once per module
@pytest.fixture(scope="module")
def module_db():
    db = Database(":memory:")
    db.create_tables()
    yield db
    db.close()

# Session scope - runs once per test session
@pytest.fixture(scope="session")
def shared_resource():
    resource = ExpensiveResource()
    yield resource
    resource.cleanup()
```

### Parameterized Fixtures

```python
@pytest.fixture(params=[1, 2, 3])
def number(request):
    """Parameterized fixture - test runs once per param."""
    return request.param

def test_numbers(number):
    """Test runs 3 times, once for each parameter."""
    assert number > 0
```

### Composing Multiple Fixtures

```python
@pytest.fixture
def user():
    return User(id=1, name="Alice")

@pytest.fixture
def admin():
    return User(id=2, name="Admin", role="admin")

def test_user_admin_interaction(user, admin):
    """Test using multiple fixtures."""
    assert admin.can_manage(user)
```

### Autouse Fixtures

```python
@pytest.fixture(autouse=True)
def reset_config():
    """Automatically runs before every test in this module."""
    Config.reset()
    yield
    Config.cleanup()

def test_without_fixture_call():
    # reset_config runs automatically
    assert Config.get_setting("debug") is False
```

### conftest.py for Shared Fixtures

```python
# tests/conftest.py
import pytest

@pytest.fixture
def client():
    """Shared fixture for all tests."""
    app = create_app(testing=True)
    with app.test_client() as client:
        yield client

@pytest.fixture
def auth_headers(client):
    """Generate auth headers for API testing."""
    response = client.post("/api/login", json={
        "username": "test",
        "password": "test",
    })
    token = response.json["token"]
    return {"Authorization": f"Bearer {token}"}
```

## Parametrization

### Basic Parametrization

```python
@pytest.mark.parametrize("text,expected", [
    ("hello", "HELLO"),
    ("world", "WORLD"),
    ("PyThOn", "PYTHON"),
])
def test_uppercase(text, expected):
    """Test runs 3 times with different inputs."""
    assert text.upper() == expected
```

### Multiple Parameters

```python
@pytest.mark.parametrize("a,b,expected", [
    (2, 3, 5),
    (0, 0, 0),
    (-1, 1, 0),
    (100, 200, 300),
])
def test_add(a, b, expected):
    """Test addition with multiple inputs."""
    assert add(a, b) == expected
```

### Parametrize with IDs

```python
@pytest.mark.parametrize("email,expected", [
    ("valid@email.com", True),
    ("invalid", False),
    ("@no-domain.com", False),
], ids=["valid-email", "missing-at", "missing-domain"])
def test_email_validation(email, expected):
    """Test email validation with readable test IDs."""
    assert is_valid_email(email) is expected
```

### Parametrized Fixtures

```python
@pytest.fixture(params=["sqlite", "postgresql", "mysql"])
def db(request):
    """Test against multiple database backends."""
    if request.param == "sqlite":
        return Database(":memory:")
    elif request.param == "postgresql":
        return Database("postgresql://localhost/test")
    elif request.param == "mysql":
        return Database("mysql://localhost/test")

def test_database_operations(db):
    """Test runs 3 times, once for each database."""
    result = db.query("SELECT 1")
    assert result is not None
```

## Markers and Test Selection

### Custom Markers

```python
# Mark slow tests
@pytest.mark.slow
def test_slow_operation():
    time.sleep(5)

# Mark integration tests
@pytest.mark.integration
def test_api_integration():
    response = requests.get("https://api.example.com")
    assert response.status_code == 200

# Mark unit tests
@pytest.mark.unit
def test_unit_logic():
    assert calculate(2, 3) == 5
```

### Run Specific Tests

```bash
# Run only fast tests
pytest -m "not slow"

# Run only integration tests
pytest -m integration

# Run integration or slow tests
pytest -m "integration or slow"

# Run tests marked as unit but not slow
pytest -m "unit and not slow"
```

### Configure Markers in pyproject.toml

```toml
[tool.pytest.ini_options]
markers = [
    "slow: marks tests as slow",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]
```

## Mocking and Patching

### Mocking Functions

```python
from unittest.mock import patch, Mock, MagicMock

@patch("mypackage.external_api_call")
def test_with_mock(api_call_mock):
    """Test with mocked external API."""
    api_call_mock.return_value = {"status": "success"}

    result = my_function()

    api_call_mock.assert_called_once()
    assert result["status"] == "success"
```

### Mocking Return Values

```python
@patch("mypackage.Database.connect")
def test_database_connection(connect_mock):
    """Test with mocked database connection."""
    connect_mock.return_value = MockConnection()

    db = Database()
    db.connect()

    connect_mock.assert_called_once_with("localhost")
```

### Mocking Exceptions

```python
@patch("mypackage.api_call")
def test_api_error_handling(api_call_mock):
    """Test error handling with mocked exception."""
    api_call_mock.side_effect = ConnectionError("Network error")

    with pytest.raises(ConnectionError):
        api_call()

    api_call_mock.assert_called_once()
```

### Mocking File I/O

```python
from unittest.mock import mock_open, patch

@patch("builtins.open", new_callable=mock_open, read_data="file content")
def test_file_reading(mock_file):
    """Test file reading with mocked open."""
    result = read_file("test.txt")

    mock_file.assert_called_once_with("test.txt", "r")
    assert result == "file content"
```

### Using autospec

```python
@patch("mypackage.DBConnection", autospec=True)
def test_autospec(db_mock):
    """Test with autospec to catch API misuse."""
    db = db_mock.return_value
    db.query("SELECT * FROM users")

    # Calls with wrong signatures fail at test time
    db_mock.assert_called_once()
```

### Mock Class Instances

```python
class TestUserService:
    @patch("mypackage.UserRepository")
    def test_create_user(self, repo_mock):
        """Test user creation with mocked repository."""
        repo_mock.return_value.save.return_value = User(id=1, name="Alice")

        service = UserService(repo_mock.return_value)
        user = service.create_user(name="Alice")

        assert user.name == "Alice"
        repo_mock.return_value.save.assert_called_once()
```

### Mock Properties

```python
from unittest.mock import Mock, PropertyMock

@pytest.fixture
def mock_config():
    """Create a mock with properties."""
    config = Mock()
    type(config).debug = PropertyMock(return_value=True)
    type(config).api_key = PropertyMock(return_value="test-key")
    return config

def test_with_mock_config(mock_config):
    """Test with mocked config properties."""
    assert mock_config.debug is True
    assert mock_config.api_key == "test-key"
```

## Testing Async Code

### Async Tests with pytest-asyncio

```python
import pytest

@pytest.mark.asyncio
async def test_async_function():
    """Test async function."""
    result = await async_add(2, 3)
    assert result == 5

@pytest.mark.asyncio
async def test_async_with_fixture(async_client):
    """Test async with async fixture."""
    response = await async_client.get("/api/users")
    assert response.status_code == 200
```

### Async Fixtures

```python
@pytest.fixture
async def async_client():
    """Async fixture providing async test client."""
    app = create_app()
    async with app.test_client() as client:
        yield client

@pytest.mark.asyncio
async def test_api_endpoint(async_client):
    """Test using async fixture."""
    response = await async_client.get("/api/data")
    assert response.status_code == 200
```

### Mocking Async Functions

```python
from unittest.mock import AsyncMock, patch

@pytest.mark.asyncio
@patch("mypackage.async_api_call", new_callable=AsyncMock)
async def test_async_mock(api_call_mock):
    """Test async function with mock."""
    api_call_mock.return_value = {"status": "ok"}

    result = await my_async_function()

    api_call_mock.assert_awaited_once()
    assert result["status"] == "ok"
```

## Testing Exceptions

### Testing Expected Exceptions

```python
def test_divide_by_zero():
    """Test that dividing by zero raises ZeroDivisionError."""
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)

def test_custom_exception():
    """Test custom exception with message."""
    with pytest.raises(ValueError, match="invalid input"):
        validate_input("invalid")
```

### Testing Exception Attributes

```python
def test_exception_with_details():
    """Test exception with custom attributes."""
    with pytest.raises(CustomError) as exc_info:
        raise CustomError("error", code=400)

    assert exc_info.value.code == 400
    assert "error" in str(exc_info.value)
```

## Testing Side Effects

### Testing with tmp_path Fixture

```python
def test_with_tmp_path(tmp_path):
    """Test using pytest's built-in tmp_path fixture (pathlib.Path)."""
    test_file = tmp_path / "test.txt"
    test_file.write_text("hello world")

    result = process_file(str(test_file))
    assert result == "hello world"
    # tmp_path is automatically cleaned up
```

### Capturing stdout/stderr

```python
def test_print_output(capsys):
    """Use capsys to assert against stdout/stderr."""
    print("hello")
    captured = capsys.readouterr()
    assert captured.out == "hello\n"
```

### Monkeypatching Environment

```python
def test_with_env_var(monkeypatch):
    """Use monkeypatch to safely set env vars or attributes."""
    monkeypatch.setenv("API_KEY", "test-key")
    assert os.environ["API_KEY"] == "test-key"
    # Reverted automatically after the test
```

## Test Organization

### Directory Structure

```text
tests/
├── conftest.py                 # Shared fixtures
├── __init__.py
├── unit/                       # Unit tests
│   ├── __init__.py
│   ├── test_models.py
│   ├── test_utils.py
│   └── test_services.py
├── integration/                # Integration tests
│   ├── __init__.py
│   ├── test_api.py
│   └── test_database.py
└── e2e/                        # End-to-end tests
    ├── __init__.py
    └── test_user_flow.py
```

### Test Classes

```python
class TestUserService:
    """Group related tests in a class."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup runs before each test in this class."""
        self.service = UserService()

    def test_create_user(self):
        """Test user creation."""
        user = self.service.create_user("Alice")
        assert user.name == "Alice"

    def test_delete_user(self):
        """Test user deletion."""
        user = User(id=1, name="Bob")
        self.service.delete_user(user)
        assert not self.service.user_exists(1)
```

## Common Patterns

### Testing API Endpoints (FastAPI/Flask)

```python
@pytest.fixture
def client():
    app = create_app(testing=True)
    return app.test_client()

def test_get_user(client):
    response = client.get("/api/users/1")
    assert response.status_code == 200
    assert response.json["id"] == 1

def test_create_user(client):
    response = client.post("/api/users", json={
        "name": "Alice",
        "email": "alice@example.com",
    })
    assert response.status_code == 201
    assert response.json["name"] == "Alice"
```

### Testing Database Operations

```python
@pytest.fixture
def db_session():
    """Create a transactional test database session."""
    session = Session(bind=engine)
    session.begin_nested()
    yield session
    session.rollback()
    session.close()

def test_create_user(db_session):
    user = User(name="Alice", email="alice@example.com")
    db_session.add(user)
    db_session.commit()

    retrieved = db_session.query(User).filter_by(name="Alice").first()
    assert retrieved.email == "alice@example.com"
```

### Testing Class Methods

```python
class TestCalculator:
    @pytest.fixture
    def calculator(self):
        return Calculator()

    def test_add(self, calculator):
        assert calculator.add(2, 3) == 5

    def test_divide_by_zero(self, calculator):
        with pytest.raises(ZeroDivisionError):
            calculator.divide(10, 0)
```

## pytest Configuration

### pyproject.toml (preferred)

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "--strict-markers",
    "--cov=mypackage",
    "--cov-report=term-missing",
    "--cov-report=html",
]
markers = [
    "slow: marks tests as slow",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]
```

### pytest.ini (legacy)

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts =
    --strict-markers
    --disable-warnings
    --cov=mypackage
    --cov-report=term-missing
    --cov-report=html
markers =
    slow: marks tests as slow
    integration: marks tests as integration tests
    unit: marks tests as unit tests
```

## Running Tests

```bash
# Run all tests
pytest

# Run a specific file
pytest tests/test_utils.py

# Run a specific test
pytest tests/test_utils.py::test_function

# Verbose output
pytest -v

# Coverage
pytest --cov=mypackage --cov-report=html

# Skip slow tests
pytest -m "not slow"

# Stop at first failure
pytest -x

# Stop after N failures
pytest --maxfail=3

# Re-run only last failures
pytest --lf

# Match by test name pattern
pytest -k "test_user"

# Drop into pdb on failure
pytest --pdb
```

## Best Practices

**DO:**
- Follow TDD: write tests before code (red-green-refactor)
- Test one behavior per test
- Use descriptive names: `test_user_login_with_invalid_credentials_fails`
- Use fixtures to eliminate duplication
- Mock external dependencies (network, filesystem, time)
- Test edge cases: empty inputs, None values, boundary conditions
- Aim for 80%+ coverage with 100% on critical paths
- Keep tests fast — use `@pytest.mark.slow` to gate integration tests

**DON'T:**
- Test implementation details — test behavior through the public API
- Use complex conditionals in tests — keep them linear
- Ignore test failures or skip flaky tests indefinitely
- Test third-party libraries — trust them to work
- Share state between tests — they must be independent
- Catch exceptions in tests — use `pytest.raises`
- Use `print` for debugging — assertions and `-v` are enough
- Over-specify mocks — brittle tests break on every refactor

## Quick Reference

| Pattern | Usage |
|---------|-------|
| `pytest.raises()` | Test expected exceptions |
| `@pytest.fixture` | Create reusable test fixtures |
| `@pytest.mark.parametrize` | Run tests with multiple inputs |
| `@pytest.mark.slow` | Gate slow tests |
| `pytest -m "not slow"` | Skip slow tests |
| `@patch()` / `Mock` | Mock functions and classes |
| `tmp_path` fixture | Automatic temp directory (pathlib.Path) |
| `monkeypatch` fixture | Safe env var / attribute patching |
| `capsys` fixture | Capture stdout / stderr |
| `pytest --cov` | Generate coverage report |

**Remember**: Tests are code too. Keep them clean, readable, and maintainable. Good tests catch bugs; great tests prevent them.
