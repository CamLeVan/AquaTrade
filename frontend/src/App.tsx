const services = [
  { name: "Marketplace", description: "Đăng và tìm lô cá giống minh bạch." },
  { name: "Escrow", description: "Tạm giữ dòng tiền trước khi giao nhận." },
  { name: "AI Digital Proof", description: "Xác thực số lượng cá qua video." },
];

export default function App() {
  return (
    <main>
      <section className="hero">
        <p className="eyebrow">AquaTrade AI</p>
        <h1>Giao dịch cá giống minh bạch và an toàn.</h1>
        <p className="intro">
          Nền tảng MVP kết nối Marketplace, Escrow và bằng chứng số từ AI.
        </p>
        <button type="button">Khám phá Marketplace</button>
      </section>
      <section className="services" aria-label="Các chức năng chính">
        {services.map((service) => (
          <article key={service.name}>
            <h2>{service.name}</h2>
            <p>{service.description}</p>
          </article>
        ))}
      </section>
    </main>
  );
}
