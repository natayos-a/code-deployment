import { useState, useEffect } from 'react';

function App() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('http://localhost:8000/api/data')
      .then(res => res.json())
      .then(data => {
        setData(data);
        setLoading(false);
      });
  }, []);

  return (
    <div style={{color: "green", textAlign: "center", fontSize: "5rem"}}>
      {loading ? 'Loading...' : `${data.message}`}
    </div>
  );
}

export default App;