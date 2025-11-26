import requests
import json

def test_analyze_race():
    url = "http://localhost:5000/api/analyze-race"
    
    # Gerçekçi bir test verisi (Linkler TJK'dan alınmalı, örnek linkler kullanıyorum)
    # Not: Bu linklerin çalışması için TJK'da geçerli olması gerekir.
    # Eğer linkler geçersizse "Veri Yok" dönecektir, bu da bir testtir.
    payload = {
        "horses": [
            {"name": "Test Atı 1", "detailLink": "/TR/YarisSever/Query/ConnectedPage/AtKosuBilgileri?1=1&QueryParameter_AtId=12345"},
            {"name": "Test Atı 2", "detailLink": "/TR/YarisSever/Query/ConnectedPage/AtKosuBilgileri?1=1&QueryParameter_AtId=67890"}
        ]
    }
    
    try:
        print("Sending request to /api/analyze-race...")
        response = requests.post(url, json=payload, timeout=30)
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print("Success:", data['success'])
            if data['success']:
                print(f"Process Time: {data.get('processTime')}s")
                print("Results:")
                print(json.dumps(data.get('results'), indent=2, ensure_ascii=False))
            else:
                print("Error:", data.get('error'))
        else:
            print("Response:", response.text)
            
    except Exception as e:
        print(f"Test Failed: {e}")

if __name__ == "__main__":
    test_analyze_race()
