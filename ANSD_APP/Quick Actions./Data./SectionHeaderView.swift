//
//  SectionHeaderView.swift
//  ANSD_APP
//


import UIKit

protocol SectionHeaderDelegate: AnyObject {
    func didTapHeader(sectionIndex: Int, categoryName: String)
}

class SectionHeaderView: UITableViewHeaderFooterView {
    
    static let identifier = "SectionHeaderView"
    weak var delegate: SectionHeaderDelegate?
    
    private var sectionIndex: Int = 0
    private var categoryTitle: String = ""
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemGray3
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    

    private let tapButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        contentView.backgroundColor = .clear
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(chevronImageView)
        contentView.addSubview(tapButton)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            chevronImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16),
            
            tapButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            tapButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            tapButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tapButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        tapButton.addTarget(self, action: #selector(headerTapped), for: .touchUpInside)
    }
    
    func configure(title: String, section: Int) {
        self.categoryTitle = title
        self.sectionIndex = section
        self.titleLabel.text = title
    }
    
    @objc private func headerTapped() {
        delegate?.didTapHeader(sectionIndex: sectionIndex, categoryName: categoryTitle)
    }
}
